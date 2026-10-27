// Validates a contact form submission and stores it in DynamoDB.
// No dependencies: the Node runtime bundles the AWS SDK v3.
import { randomUUID } from "node:crypto";
import { DynamoDBClient, PutItemCommand } from "@aws-sdk/client-dynamodb";

const client = new DynamoDBClient({});
const TABLE_NAME = process.env.TABLE_NAME;
const RETENTION_SECONDS = 180 * 24 * 60 * 60;
const MAX_BODY_BYTES = 32 * 1024;

const LIMITS = { name: [1, 100], email: [3, 254], message: [1, 5000] };
const EMAIL_PATTERN = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

// Thrown for anything wrong with the request itself; becomes a 400 with its message
class ClientError extends Error {
  constructor(message, options) {
    super(message, options);
    this.name = "ClientError";
  }
}

const respond = (statusCode, body) => ({
  statusCode,
  headers: { "content-type": "application/json" },
  body: JSON.stringify(body),
});

const parseBody = (event) => {
  const raw = event.isBase64Encoded
    ? Buffer.from(event.body ?? "", "base64").toString("utf8")
    : event.body ?? "";

  const size = Buffer.byteLength(raw, "utf8");
  if (size > MAX_BODY_BYTES) {
    throw new ClientError(`body is ${size} bytes, limit is ${MAX_BODY_BYTES}`);
  }

  let parsed;
  try {
    parsed = JSON.parse(raw);
  } catch (err) {
    throw new ClientError("body is not valid JSON", { cause: err });
  }

  if (parsed === null || typeof parsed !== "object" || Array.isArray(parsed)) {
    throw new ClientError("body must be a JSON object");
  }
  return parsed;
};

const validate = (input) => {
  const fields = {};
  for (const [key, [min, max]] of Object.entries(LIMITS)) {
    if (typeof input[key] !== "string") {
      throw new ClientError(`${key} must be a string`);
    }
    const value = input[key].trim();
    if (value.length < min || value.length > max) {
      throw new ClientError(`${key} must be ${min}-${max} characters, got ${value.length}`);
    }
    fields[key] = value;
  }
  if (!EMAIL_PATTERN.test(fields.email)) {
    throw new ClientError("email is not a valid address");
  }
  return fields;
};

const save = async (fields, http) => {
  const now = new Date();
  const createdAt = now.toISOString();
  const id = randomUUID();

  const item = {
    pk: { S: createdAt.slice(0, 7) },
    sk: { S: `${createdAt}#${id}` },
    id: { S: id },
    name: { S: fields.name },
    email: { S: fields.email },
    message: { S: fields.message },
    createdAt: { S: createdAt },
    expiresAt: { N: String(Math.floor(now.getTime() / 1000) + RETENTION_SECONDS) },
  };
  if (http.sourceIp) item.sourceIp = { S: http.sourceIp };
  if (http.userAgent) item.userAgent = { S: http.userAgent.slice(0, 500) };

  await client.send(new PutItemCommand({
    TableName: TABLE_NAME,
    Item: item,
    ConditionExpression: "attribute_not_exists(sk)",
  }));
  return id;
};

export const handler = async (event) => {
  try {
    const fields = validate(parseBody(event));
    const id = await save(fields, event.requestContext?.http ?? {});
    console.info("message saved", { id });
    return respond(200, { ok: true });
  } catch (err) {
    if (err instanceof ClientError) {
      console.warn("rejected request", err);
      return respond(400, { ok: false, error: err.message });
    }
    console.error("failed to handle request", err);
    return respond(500, { ok: false, error: "internal error" });
  }
};
