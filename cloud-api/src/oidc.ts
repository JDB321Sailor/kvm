import { generators, Issuer, Client } from "openid-client";
import express from "express";
import { prisma } from "./db";
import { BadRequestError } from "./errors";
import * as crypto from "crypto";

const API_HOSTNAME = process.env.API_HOSTNAME;
const APP_HOSTNAME = process.env.APP_HOSTNAME;
const REDIRECT_URI = `${API_HOSTNAME}/oidc/callback`;
const AUTH_PROVIDER = process.env.AUTH_PROVIDER || 'google';

const getOIDCClient = async (): Promise<Client> => {
  if (AUTH_PROVIDER === 'google') {
    const googleIssuer = await Issuer.discover("https://accounts.google.com");
    return new googleIssuer.Client({
      client_id: process.env.GOOGLE_CLIENT_ID!,
      client_secret: process.env.GOOGLE_CLIENT_SECRET!,
      redirect_uris: [REDIRECT_URI],
      response_types: ["code"],
    });
  } else if (AUTH_PROVIDER === 'authentik') {
    if (!process.env.AUTHENTIK_ISSUER) {
      throw new Error("AUTHENTIK_ISSUER is required when using Authentik authentication");
    }
    
    const authentikIssuer = await Issuer.discover(process.env.AUTHENTIK_ISSUER);
    return new authentikIssuer.Client({
      client_id: process.env.AUTHENTIK_CLIENT_ID!,
      client_secret: process.env.AUTHENTIK_CLIENT_SECRET!,
      redirect_uris: [REDIRECT_URI],
      response_types: ["code"],
    });
  } else {
    throw new Error(`Unsupported authentication provider: ${AUTH_PROVIDER}`);
  }
};

export const Login = async (req: express.Request, res: express.Response) => {
  const state = new URLSearchParams();

  // Generate a CSRF token and store it in the session, so the callback
  // can ensure that the request is the same as the one that was initiated.
  state.set("csrf", generators.state());
  req.session!.csrf = state.get("csrf");

  req.session!.deviceId = req.body.deviceId;
  req.session!.returnTo = req.body.returnTo;

  const code_verifier = generators.codeVerifier();
  const code_challenge = generators.codeChallenge(code_verifier);
  req.session!.code_verifier = code_verifier;

  const client = await getOIDCClient();
  const authorizationUrl = client.authorizationUrl({
    scope: "openid email profile",
    state: state.toString(),
    // This ensures that to even issue the token, the client must have the code_verifier,
    // which is stored in the session cookie.
    code_challenge,
    code_challenge_method: "S256",
  });
  return res.redirect(authorizationUrl);
};

// Keep Google route for backward compatibility
export const Google = Login;

export const Callback = async (req: express.Request, res: express.Response) => {
  const client = await getOIDCClient();

  // Retrieve recognized callback parameters from the request, e.g. code and state
  const params = client.callbackParams(req);
  if (!params)
    throw new BadRequestError("Missing callback parameters", "missing_callback_params");

  const sessionCsrf = req.session?.csrf;
  if (!sessionCsrf) {
    throw new BadRequestError("Missing CSRF in session", "missing_csrf");
  }

  const thisRequestCsrf = new URLSearchParams(params.state).get("csrf");
  if (thisRequestCsrf !== sessionCsrf) {
    throw new BadRequestError("Invalid CSRF", "invalid_csrf");
  }

  const deviceId = req.session?.deviceId as string | undefined;
  const returnTo = (req.session?.returnTo ?? `${APP_HOSTNAME}/devices`) as string;

  req.session!.csrf = null;
  req.session!.returnTo = null;
  req.session!.deviceId = null;

  // Exchange code for access token and ID token
  const tokenSet = await client.callback(REDIRECT_URI, params, {
    state: req.query.state?.toString(),
    code_verifier: req.session?.code_verifier,
  });

  const userInfo = await client.userinfo(tokenSet);

  // TokenClaims is an object that contains the sub, email, name and other claims
  const tokenClaims = tokenSet.claims();
  if (!tokenClaims) {
    throw new BadRequestError("Missing claims in token", "missing_claims");
  }

  if (!tokenSet.id_token) {
    throw new BadRequestError("Missing ID Token", "missing_id_token");
  }

  req.session!.id_token = tokenSet.id_token;

  // Handle user creation/update based on provider
  let user;
  if (AUTH_PROVIDER === 'google') {
    user = await prisma.user.upsert({
      where: { googleId: tokenClaims.sub },
      update: {
        googleId: tokenClaims.sub,
        email: userInfo.email,
        picture: userInfo.picture,
      },
      create: {
        googleId: tokenClaims.sub,
        email: userInfo.email,
        picture: userInfo.picture,
      },
    });
  } else if (AUTH_PROVIDER === 'authentik') {
    user = await prisma.user.upsert({
      where: { authentikId: tokenClaims.sub },
      update: {
        authentikId: tokenClaims.sub,
        email: userInfo.email,
        picture: userInfo.picture,
      },
      create: {
        authentikId: tokenClaims.sub,
        email: userInfo.email,
        picture: userInfo.picture,
      },
    });
  }

  // This means the user is trying to adopt a device by first logging/signin up/in
  if (deviceId) {
    const deviceAdopted = await prisma.device.findUnique({
      where: { id: deviceId },
      select: { user: { select: { googleId: true, authentikId: true } } },
    });

    const currentUserId = AUTH_PROVIDER === 'google' ? tokenClaims.sub : tokenClaims.sub;
    const deviceOwnerId = AUTH_PROVIDER === 'google' ? 
      deviceAdopted?.user.googleId : 
      deviceAdopted?.user.authentikId;

    const isAdoptedByCurrentUser = deviceOwnerId === currentUserId;
    const isAdoptedByOther = deviceAdopted && !isAdoptedByCurrentUser;
    
    if (isAdoptedByOther) {
      // Device is already adopted by another user. This can happen if:
      // 1. The device was resold without being de-registered by the previous owner.
      // 2. Someone is trying to adopt a device they don't own.
      //
      // Security note:
      // The previous owner can't connect to the device anymore because:
      // - The device would have done a hardware reset, erasing its deviceToken.
      // - Without a valid deviceToken, the device can't connect to the cloud API.
      //
      // This check prevents unauthorized adoption and ensures proper ownership transfer.
      // The cost of this check is therefore, that the previous owner has to re-register the device.
      return res.redirect(`${APP_HOSTNAME}/already-adopted`);
    }

    // Temp Token expires in 5 minutes
    const tempToken = crypto.randomBytes(20).toString("hex");
    const tempTokenExpiresAt = new Date(new Date().getTime() + 5 * 60000);

    const whereClause = AUTH_PROVIDER === 'google' ? 
      { googleId: tokenClaims.sub } : 
      { authentikId: tokenClaims.sub };

    await prisma.user.update({
      where: whereClause,
      data: {
        device: {
          upsert: {
            create: { id: deviceId, tempToken, tempTokenExpiresAt },
            where: { id: deviceId },
            update: { tempToken, tempTokenExpiresAt },
          },
        },
      },
    });

    console.log("Adopted device", deviceId, "for user", tokenClaims.sub, "via", AUTH_PROVIDER);

    const url = new URL(returnTo);
    url.searchParams.append("tempToken", tempToken);
    url.searchParams.append("deviceId", deviceId);
    
    if (AUTH_PROVIDER === 'google') {
      url.searchParams.append("oidcGoogle", tokenSet.id_token.toString());
      url.searchParams.append("clientId", process.env.GOOGLE_CLIENT_ID!);
    } else {
      url.searchParams.append("oidcAuthentik", tokenSet.id_token.toString());
      url.searchParams.append("clientId", process.env.AUTHENTIK_CLIENT_ID!);
    }
    
    return res.redirect(url.toString());
  }
  return res.redirect(returnTo);
};
