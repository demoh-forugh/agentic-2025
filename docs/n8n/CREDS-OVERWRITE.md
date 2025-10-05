# n8n Credentials Configuration

## ⚠️ Important Understanding

**CREDENTIALS_OVERWRITE_DATA does NOT automatically create credentials.** It only pre-fills field values when users manually create new credentials in the n8n UI.

### What It Does
- Pre-fills credential field values (like baseUrl, host, password)
- Hides overwritten fields from users (they become read-only)
- Useful for OAuth where you want "click to connect" without entering client secrets

### What It Doesn't Do
- ❌ Does not automatically create credential entries
- ❌ Does not automatically assign credentials to imported workflows
- ❌ Workflows imported with credential references will still prompt users to select/create credentials

## Environment Variables for Credentials

Source: [n8n Documentation - Credentials Environment Variables](https://docs.n8n.io/hosting/configuration/environment-variables/credentials/)

### Enable Credential Overwrites

Use the following environment variables to enable credential overwrites.

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `CREDENTIALS_OVERWRITE_DATA` | JSON | - | Inline JSON with credential overwrites (not recommended due to escaping issues) |
| `CREDENTIALS_OVERWRITE_DATA_FILE` | String | - | Path to JSON file with credential overwrites (recommended) |
| `CREDENTIALS_OVERWRITE_ENDPOINT` | String | - | REST API endpoint to fetch credentials dynamically |
| `CREDENTIALS_DEFAULT_NAME` | String | "My credentials" | The default name for credentials |

**Security Note:** Using environment variables for credentials isn't recommended, as environment variables aren't protected in n8n and the data can leak to users. The recommended approach is loading data via `CREDENTIALS_OVERWRITE_ENDPOINT`.

## Configuration Methods

Source: [n8n Documentation - Configuration Methods](https://docs.n8n.io/hosting/configuration/configuration-methods/)

### Set Environment Variables by Command Line

#### npm

For npm, set your desired environment variables in terminal. The command depends on your command line.

**Bash CLIs:**
```bash
export <variable>=<value>
```

**cmd.exe:**
```cmd
set <variable>=<value>
```

**PowerShell:**
```powershell
$env:<variable>=<value>
```

### Docker

In Docker you can use the `-e` flag from the command line:

```bash
docker run -it --rm \
  --name n8n \
  -p 5678:5678 \
  -e N8N_TEMPLATES_ENABLED="false" \
  docker.n8n.io/n8nio/n8n
```

### Docker Compose File

In Docker, you can set your environment variables in the `n8n: environment:` element of your `docker-compose.yaml` file.

Example:

```yaml
n8n:
    environment:
      - N8N_TEMPLATES_ENABLED=false
```

## Keeping Sensitive Data in Separate Files

You can append `_FILE` to individual environment variables to provide their configuration in a separate file, enabling you to avoid passing sensitive details using environment variables. n8n loads the data from the file with the given name, making it possible to load data from Docker-Secrets and Kubernetes-Secrets.

While most environment variables can use the `_FILE` suffix, it's more beneficial for sensitive data such as credentials and database configuration. Here are some examples:

```bash
# Credentials
CREDENTIALS_OVERWRITE_DATA_FILE=/path/to/credentials_data

# Database Configuration
DB_TYPE_FILE=/path/to/db_type
DB_POSTGRESDB_DATABASE_FILE=/path/to/database_name
DB_POSTGRESDB_HOST_FILE=/path/to/database_host
DB_POSTGRESDB_PORT_FILE=/path/to/database_port
DB_POSTGRESDB_USER_FILE=/path/to/database_user
DB_POSTGRESDB_PASSWORD_FILE=/path/to/database_password
DB_POSTGRESDB_SCHEMA_FILE=/path/to/database_schema

# SSL Configuration
DB_POSTGRESDB_SSL_CA_FILE=/path/to/ssl_ca
DB_POSTGRESDB_SSL_CERT_FILE=/path/to/ssl_cert
DB_POSTGRESDB_SSL_KEY_FILE=/path/to/ssl_key
DB_POSTGRESDB_SSL_REJECT_UNAUTHORIZED_FILE=/path/to/ssl_reject_unauth
```

## n8n Credential Overwrite

In n8n, credential overwrites allow administrators to predefine or restrict credential values for workflows. This is particularly useful in self-hosted environments to manage sensitive data securely or simplify user interactions.

### Using Credential Overwrites

1. **Enable Credential Overwrites**  
   Set the `CREDENTIALS_OVERWRITE_DATA` environment variable in your n8n configuration. This variable defines the credentials to be overwritten. For example, in a Docker setup, add the following to your `docker-compose.yml`:

   ```yaml
   environment:
     - CREDENTIALS_OVERWRITE_DATA={"postgres":{"user":"admin","password":"securepassword"}}
   ```

   This ensures that the specified credentials (e.g., PostgreSQL) are preconfigured and cannot be modified by users.

2. **Fetch Credentials from an API Endpoint**  
   You can also fetch credentials dynamically by setting the `CREDENTIALS_OVERWRITE_ENDPOINT` environment variable. For example:

   ```yaml
   environment:
     - CREDENTIALS_OVERWRITE_ENDPOINT=https://example.com/credentials
   ```

   This endpoint should return a JSON object with the credentials structure similar to `CREDENTIALS_OVERWRITE_DATA`.

### Behavior and Use Cases

- **Predefined Values**: Overwritten credentials act as defaults when creating new credentials in n8n.
- **Restricted Editing**: Users cannot modify these predefined values, ensuring consistency and security.
- **Simplified OAuth**: Useful for OAuth-based integrations where users only need to click "Connect" without entering client details.

### Best Practices

- Use `CREDENTIALS_OVERWRITE_DATA` for static configurations and `CREDENTIALS_OVERWRITE_ENDPOINT` for dynamic setups.
- Test configurations thoroughly to ensure workflows execute correctly with the overwritten credentials.
- Keep sensitive data secure by using environment variables or external secret management tools.

By leveraging credential overwrites, you can streamline workflow management while maintaining security and consistency across deployments.

## References

- [n8n Documentation](https://docs.n8n.io)
- [n8n GitHub Repository](https://github.com/n8n-io/n8n)
- [n8n Community](https://community.n8n.io)

