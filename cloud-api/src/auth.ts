import { type NextFunction, type Request, type Response } from "express";
import * as jose from "jose";
import { UnauthorizedError } from "./errors";

export const verifyToken = async (idToken: string) => {
  const authProvider = process.env.AUTH_PROVIDER || 'google';
  
  let JWKS: any;
  let issuer: string;
  let audience: string | undefined;
  
  if (authProvider === 'google') {
    JWKS = jose.createRemoteJWKSet(
      new URL("https://www.googleapis.com/oauth2/v3/certs"),
    );
    issuer = "https://accounts.google.com";
    audience = process.env.GOOGLE_CLIENT_ID;
  } else if (authProvider === 'authentik') {
    if (!process.env.AUTHENTIK_JWKS_URL) {
      throw new Error("AUTHENTIK_JWKS_URL is required when using Authentik authentication");
    }
    JWKS = jose.createRemoteJWKSet(
      new URL(process.env.AUTHENTIK_JWKS_URL),
    );
    issuer = process.env.AUTHENTIK_ISSUER!;
    audience = process.env.AUTHENTIK_CLIENT_ID;
  } else {
    throw new Error(`Unsupported authentication provider: ${authProvider}`);
  }

  try {
    const { payload } = await jose.jwtVerify(idToken, JWKS, {
      issuer,
      audience,
    });

    return payload;
  } catch (e) {
    console.error('Token verification failed:', e);
    return null;
  }
};

export const authenticated = async (req: Request, res: Response, next: NextFunction) => {
  const idToken = req.session?.id_token;
  if (!idToken) throw new UnauthorizedError();

  const payload = await verifyToken(idToken);
  if (!payload) throw new UnauthorizedError();
  if (!payload.exp) throw new UnauthorizedError();

  if (new Date(payload.exp * 1000) < new Date()) {
    throw new UnauthorizedError();
  }

  next();
};
