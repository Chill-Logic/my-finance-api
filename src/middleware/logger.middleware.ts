import { Injectable, NestMiddleware, Logger } from "@nestjs/common";
import { Request, Response, NextFunction } from "express";

@Injectable()
export class LoggerMiddleware implements NestMiddleware {
  private logger = new Logger("HTTP");

  use(req: Request, res: Response, next: NextFunction): void {
    const { method, originalUrl, body, query, params } = req;
    const start = Date.now();

    res.on("finish", () => {
      const duration = Date.now() - start;
      const { statusCode } = res;

      this.logger.log(
        `${method} ${originalUrl} ${statusCode} - ${duration}ms\n` +
          `  Params: ${JSON.stringify(params)}\n` +
          `  Query: ${JSON.stringify(query)}\n` +
          `  Body: ${JSON.stringify(body)}`,
      );
    });

    next();
  }
}