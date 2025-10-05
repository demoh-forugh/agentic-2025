# n8n Configuration Reference

This document contains n8n environment variable configurations extracted from official documentation for development reference.

---

## Complete Environment Variables Reference

**Source**: https://docs.n8n.io/hosting/configuration/environment-variables/

---

## Timezone Configuration

**Our Workshop Timezone**: `America/New_York`

**Source**: https://docs.n8n.io/hosting/configuration/configuration-examples/time-zone/

The default timezone is `America/New_York`. The Schedule node uses this to determine workflow start times. To set a different timezone:

```bash
export GENERIC_TIMEZONE=Europe/Berlin
```

## Execution Data Management

**Source**: https://docs.n8n.io/hosting/scaling/execution-data/

Depending on your execution settings and volume, your n8n database can grow in size and run out of storage. n8n recommends not saving unnecessary data and enabling pruning of old execution data.

### Reduce Saved Data

**Note**: You can also configure these settings on an individual workflow basis using the workflow settings.

You can select which execution data n8n saves. For example, save only executions that result in an error:

#### NPM Configuration
```bash
# Save executions ending in errors
export EXECUTIONS_DATA_SAVE_ON_ERROR=all

# Don't save successful executions
export EXECUTIONS_DATA_SAVE_ON_SUCCESS=none

# Don't save node progress for each execution
export EXECUTIONS_DATA_SAVE_ON_PROGRESS=false

# Don't save manually launched executions
export EXECUTIONS_DATA_SAVE_MANUAL_EXECUTIONS=false
```

#### Docker Run Configuration
```bash
docker run -it --rm \
 --name n8n \
 -p 5678:5678 \
 -e EXECUTIONS_DATA_SAVE_ON_ERROR=all \
 -e EXECUTIONS_DATA_SAVE_ON_SUCCESS=none \
 -e EXECUTIONS_DATA_SAVE_ON_PROGRESS=true \
 -e EXECUTIONS_DATA_SAVE_MANUAL_EXECUTIONS=false \
 docker.n8n.io/n8nio/n8n
```

#### NPM Configuration
```bash
# Enable executions pruning
export EXECUTIONS_DATA_PRUNE=true

# How old (hours) a finished execution must be to qualify for soft-deletion
export EXECUTIONS_DATA_MAX_AGE=168

# Max number of finished executions to keep. Set to 0 for unlimited.
export EXECUTIONS_DATA_PRUNE_MAX_COUNT=50000
```

#### Docker Run Configuration
```bash
docker run -it --rm \
 --name n8n \
 -p 5678:5678 \
 -e EXECUTIONS_DATA_PRUNE=true \
 -e EXECUTIONS_DATA_MAX_AGE=168 \
 docker.n8n.io/n8nio/n8n
```

#### Docker Compose Configuration
```yaml
  environment:
    - EXECUTIONS_DATA_PRUNE=true
    - EXECUTIONS_DATA_MAX_AGE=168
    - EXECUTIONS_DATA_PRUNE_MAX_COUNT=50000
```

**Note**: You can add `_FILE` to individual variables to provide their configuration in a separate file. Refer to Keeping sensitive data in separate files for more details.

### Execution Environment Variables

This page lists environment variables to configure workflow execution settings.

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `EXECUTIONS_MODE` | Enum: `regular`, `queue` | `regular` | Whether executions should run directly or using queue. Refer to Queue mode for more details. |
| `EXECUTIONS_TIMEOUT` | Number | `-1` | Sets a default timeout (in seconds) to all workflows after which n8n stops their execution. Users can override this for individual workflows up to the duration set in `EXECUTIONS_TIMEOUT_MAX`. Set to `-1` to disable. |
| `EXECUTIONS_TIMEOUT_MAX` | Number | `3600` | The maximum execution time (in seconds) that users can set for an individual workflow. |
| `EXECUTIONS_DATA_SAVE_ON_ERROR` | Enum: `all`, `none` | `all` | Whether n8n saves execution data on error. |
| `EXECUTIONS_DATA_SAVE_ON_SUCCESS` | Enum: `all`, `none` | `all` | Whether n8n saves execution data on success. |
| `EXECUTIONS_DATA_SAVE_ON_PROGRESS` | Boolean | `false` | Whether to save progress for each node executed (`true`) or not (`false`). |
| `EXECUTIONS_DATA_SAVE_MANUAL_EXECUTIONS` | Boolean | `true` | Whether to save data of executions when started manually. |
| `EXECUTIONS_DATA_PRUNE` | Boolean | `true` | Whether to delete data of past executions on a rolling basis. |
| `EXECUTIONS_DATA_MAX_AGE` | Number | `336` | The execution age (in hours) before it's deleted. |
| `EXECUTIONS_DATA_PRUNE_MAX_COUNT` | Number | `10000` | Maximum number of executions to keep in the database. `0` = no limit. |
| `EXECUTIONS_DATA_HARD_DELETE_BUFFER` | Number | `1` | How old (hours) the finished execution data has to be to get hard-deleted. By default, this buffer excludes recent executions as the user may need them while building a workflow. |
| `EXECUTIONS_DATA_PRUNE_HARD_DELETE_INTERVAL` | Number | `15` | How often (minutes) execution data should be hard-deleted. |
| `EXECUTIONS_DATA_PRUNE_SOFT_DELETE_INTERVAL` | Number | `60` | How often (minutes) execution data should be soft-deleted. |
| `N8N_CONCURRENCY_PRODUCTION_LIMIT` | Number | `-1` | Max production executions allowed to run concurrently, in both regular and scaling modes. `-1` to disable in regular mode. |

---

## Database Configuration

**Source**: https://docs.n8n.io/hosting/configuration/environment-variables/database/

### Overview

By default, n8n uses **SQLite**. n8n also supports **PostgreSQL**.

**Note**: n8n deprecated support for MySQL and MariaDB in v1.0.

**File-based configuration**: You can add `_FILE` to individual variables to provide their configuration in a separate file. Refer to Keeping sensitive data in separate files for more details.

### General Database Variables

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `DB_TYPE` | Enum: `sqlite`, `postgresdb` | `sqlite` | The database to use. |
| `DB_TABLE_PREFIX` | String | - | Prefix to use for table names. |
| `DB_PING_INTERVAL_SECONDS` | Number | `2` | The interval, in seconds, between pings to the database to check if the connection is still alive. |

### PostgreSQL Configuration

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `DB_POSTGRESDB_DATABASE` | String | `n8n` | The name of the PostgreSQL database. |
| `DB_POSTGRESDB_HOST` | String | `localhost` | The PostgreSQL host. |
| `DB_POSTGRESDB_PORT` | Number | `5432` | The PostgreSQL port. |
| `DB_POSTGRESDB_USER` | String | `postgres` | The PostgreSQL user. |
| `DB_POSTGRESDB_PASSWORD` | String | - | The PostgreSQL password. |
| `DB_POSTGRESDB_POOL_SIZE` | Number | `2` | Control how many parallel open Postgres connections n8n should have. Increasing it may help with resource utilization, but too many connections may degrade performance. |
| `DB_POSTGRESDB_CONNECTION_TIMEOUT` | Number | `20000` | Postgres connection timeout (ms). |
| `DB_POSTGRESDB_IDLE_CONNECTION_TIMEOUT` | Number | `30000` | Amount of time before an idle connection is eligible for eviction for being idle. |
| `DB_POSTGRESDB_SCHEMA` | String | `public` | The PostgreSQL schema. |
| `DB_POSTGRESDB_SSL_ENABLED` | Boolean | `false` | Whether to enable SSL. Automatically enabled if `DB_POSTGRESDB_SSL_CA`, `DB_POSTGRESDB_SSL_CERT` or `DB_POSTGRESDB_SSL_KEY` is defined. |
| `DB_POSTGRESDB_SSL_CA` | String | - | The PostgreSQL SSL certificate authority. |
| `DB_POSTGRESDB_SSL_CERT` | String | - | The PostgreSQL SSL certificate. |
| `DB_POSTGRESDB_SSL_KEY` | String | - | The PostgreSQL SSL key. |
| `DB_POSTGRESDB_SSL_REJECT_UNAUTHORIZED` | Boolean | `true` | If n8n should reject unauthorized SSL connections (`true`) or not (`false`). |

**Note**: All PostgreSQL variables support `_FILE` suffix for file-based configuration (e.g., `DB_POSTGRESDB_PASSWORD_FILE`).

### SQLite Configuration

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `DB_SQLITE_POOL_SIZE` | Number | `0` | Controls whether to open the SQLite file in WAL mode or rollback journal mode. Uses rollback journal mode when set to zero. When greater than zero, uses WAL mode with the value determining the number of parallel SQL read connections to configure. WAL mode is much more performant and reliable than the rollback journal mode. |
| `DB_SQLITE_VACUUM_ON_STARTUP` | Boolean | `false` | Runs VACUUM operation on startup to rebuild the database. Reduces file size and optimizes indexes. This is a long running blocking operation and increases start-up time. |

---