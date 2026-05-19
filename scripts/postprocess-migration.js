#!/usr/bin/env node

const fs = require('fs');
const path = require('path');

require('dotenv/config');

const migrationsDir = path.resolve(__dirname, '../src/migrations');

const migrationFile = findLatestMigrationFile(migrationsDir);
if (!migrationFile) {
  console.log('No migration files found to post-process.');
  process.exit(0);
}

let content = fs.readFileSync(migrationFile, 'utf8');

if (content.includes('private getSchemaName(): string') || content.includes('${schemaName}')) {
  console.log(`Migration already dynamic: ${path.basename(migrationFile)}`);
  process.exit(0);
}

const schemaFromEnv = process.env.DB_SCHEMA;
const schemaFromFile = inferSchemaFromFile(content);
const schemaCandidates = [];

if (schemaFromEnv) {
  schemaCandidates.push(schemaFromEnv);
}

if (schemaFromFile && schemaFromFile !== schemaFromEnv) {
  schemaCandidates.push(schemaFromFile);
}

const schemaName = schemaCandidates.find(candidate => content.includes(`"${candidate}"`));

if (!schemaName) {
  console.error('Schema could not be resolved. Set DB_SCHEMA or ensure migration uses schema-qualified tables.');
  process.exit(1);
}

const schemaLiteral = `"${schemaName}"`;
const dynamicSchemaLiteral = '"${schemaName}"';

content = content.split(schemaLiteral).join(dynamicSchemaLiteral);

const eol = content.includes('\r\n') ? '\r\n' : '\n';
const schemaDecl = '    const schemaName = this.getSchemaName();';

if (!content.includes(schemaDecl)) {
  content = insertSchemaDecl(content, eol, 'up');
  content = insertSchemaDecl(content, eol, 'down');
}

if (!content.includes('private getSchemaName(): string')) {
  content = addSchemaHelper(content, eol);
}

fs.writeFileSync(migrationFile, content, 'utf8');
console.log(`Post-processed migration: ${path.basename(migrationFile)}`);

function findLatestMigrationFile(dirPath) {
  if (!fs.existsSync(dirPath)) {
    return null;
  }

  const files = fs.readdirSync(dirPath).filter(file => /^Migration\d+\.ts$/.test(file));
  if (files.length === 0) {
    return null;
  }

  files.sort();
  return path.join(dirPath, files[files.length - 1]);
}

function inferSchemaFromFile(fileContent) {
  const createSchemaMatch = fileContent.match(/create schema if not exists "([^"]+)"/i);
  if (createSchemaMatch) {
    return createSchemaMatch[1];
  }

  const qualifiedTableMatch = fileContent.match(/"([^"]+)"\."[^"]+"/);
  if (qualifiedTableMatch) {
    return qualifiedTableMatch[1];
  }

  return null;
}

function insertSchemaDecl(fileContent, eol, method) {
  const regex = new RegExp(`override async ${method}\\(\\): Promise<void> \\{(\\r?\\n)`);

  if (!regex.test(fileContent)) {
    console.warn(`Could not find ${method}() in migration to insert schema declaration.`);
    return fileContent;
  }

  return fileContent.replace(regex, (_match, newline) => {
    return `override async ${method}(): Promise<void> {${newline}${schemaDecl}${newline}${newline}`;
  });
}

function addSchemaHelper(fileContent, eol) {
  const helperLines = [
    '  private getSchemaName(): string {',
    '    const schemaName = process.env.DB_SCHEMA;',
    '',
    '    if (!schemaName) {',
    "      throw new Error('DB_SCHEMA is not set');",
    '    }',
    '',
    '    return schemaName;',
    '  }'
  ];

  const helperBlock = helperLines.join(eol);

  return fileContent.replace(/\r?\n}\s*$/, `${eol}${helperBlock}${eol}${eol}}${eol}`);
}
