import pino from "pino";
import packageJson from "../../package.json" with { type: "json" };
import { env } from "./env.js";

const transport =
  env.NODE_ENV === "development"
    ? pino.transport({
        target: "pino-pretty",
        options: {
          colorize: true,
          translateTime: "SYS:standard"
        }
      })
    : undefined;

const rootLogger = pino(
  {
    level: env.LOG_LEVEL,
    base: {
      service: "foreman-backend",
      version: packageJson.version
    }
  },
  transport
);

export const createLogger = (name: string): pino.Logger => {
  return rootLogger.child({ name });
};
