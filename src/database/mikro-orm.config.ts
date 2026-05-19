import 'dotenv/config';
import { Options } from '@mikro-orm/core';
import { PostgreSqlDriver } from '@mikro-orm/postgresql';

const config: Options = {
  driver: PostgreSqlDriver,
  host: process.env.DB_HOST,
  port: Number(process.env.DB_PORT),
  dbName: process.env.DB_NAME,
  schema: process.env.DB_SCHEMA,
  user: process.env.DB_USERNAME,
  password: process.env.DB_PASSWORD,
  schemaGenerator: {
    ignoreSchema: ['auth', 'storage', 'realtime', 'vault'],
  },

  entities: ['dist/**/*.entity.js'],
  entitiesTs: ['src/**/*.entity.ts'],

  migrations: {
    path: 'dist/migrations',
    pathTs: 'src/migrations',
    glob: '!(*.d).{js,ts}',
  },
};

export default config;
