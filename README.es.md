# 📋 Daily Standup Skill

> Automatiza tu resumen para la daily — commits, tareas y eventos del calendario en un solo comando.

Un skill para agentes de IA que genera tu reporte de daily standup usando datos de Git, tu gestor de tareas y tu calendario. Funciona con **Notion**, **Linear**, **GitHub Issues** y **Jira**. Compatible con [Craft Agent](https://craft.do/agents), [Claude Code](https://docs.anthropic.com/en/docs/claude-code), [Cursor](https://cursor.sh) y cualquier agente que soporte el [formato SKILL.md](https://skills.sh).

[Read in English](README.md)

## Instalación rápida

### Instalador interactivo (recomendado)

```bash
curl -fsSL https://raw.githubusercontent.com/yelloalejo/daily-standup-skill/main/install.sh | bash
```

El instalador te deja elegir dónde instalar:
- **Global** (`~/.agents/skills/`) — funciona con Claude Code, Cursor, Craft Agent y cualquier agente compatible con SKILL.md
- **Workspace de Craft Agent** — si se detecta, instalar en un workspace específico con templates de sources

También acepta flags:
```bash
# Instalar globalmente (saltar selección)
curl ... | bash -s -- --global

# Instalar en un workspace específico
curl ... | bash -s -- --workspace my-workspace

# Solo instalar archivos, configurar después via /daily-standup
curl ... | bash -s -- --global --skip-config
```

### Usando npx skills (ecosistema skills.sh)

```bash
npx skills add yelloalejo/daily-standup-skill
```

> Instala los archivos del skill globalmente. La configuración se hace interactivamente la primera vez que ejecutas `/daily-standup`.

## Uso

En tu agente de IA, escribe:

```
/daily-standup
```

El skill generará un resumen como:

> **Ayer:**
> Estuve trabajando en la corrección del flujo de autenticación y agregué tests unitarios para el módulo de pagos.
>
> **Hoy:**
> Voy a continuar con la integración del webhook de Stripe. Tengo una reunión de equipo a las 10am y un 1:1 a las 3pm.

Más secciones detalladas con commits, tareas y reuniones.

## Integraciones soportadas

| Integración | Tipo | Para qué |
|-------------|------|----------|
| **GitHub** | Requerido | Commits por rama |
| **Notion** | Proveedor de tareas | Tareas del sprint board |
| **Linear** | Proveedor de tareas | Issues del ciclo |
| **GitHub Issues** | Proveedor de tareas | Issues del repositorio |
| **Jira** | Proveedor de tareas | Tickets del sprint |
| **Google Calendar** | Opcional | Reuniones de hoy |

## Configuración

Después de instalar, tu config queda en:
```
~/.craft-agent/workspaces/{workspace}/skills/daily-standup/config.json
```

Ver [config.example.json](skills/daily-standup/config.example.json) para el esquema completo.

### Campos principales

| Campo | Descripción |
|-------|-------------|
| `user.name` | Tu nombre (para filtrar commits y tareas) |
| `user.gitEmail` | Email usado en git |
| `user.calendarEmails` | Emails para verificar eventos declinados |
| `git.owner` / `git.repo` | Org y repositorio de GitHub |
| `tasks.provider` | `notion`, `linear`, `github-issues`, `jira`, o `none` |
| `calendar.provider` | `google-calendar` o `none` |
| `calendar.timezone` | Tu zona horaria (ej: `America/Bogota`) |
| `output.language` | `en` o `es` |

## Autenticación de Sources

Después de instalar, necesitas autenticar cada source en tu agente:

### GitHub
1. Crea un [Personal Access Token](https://github.com/settings/tokens) con acceso a repos
2. Actualiza el token en `~/.craft-agent/.../sources/github/config.json`

### Notion
1. Crea una integración en [notion.so/my-integrations](https://notion.so/my-integrations)
2. Comparte tu base de datos de tareas con la integración
3. Actualiza el token en el config de la source

### Linear
1. La autenticación es via OAuth — tu agente te pedirá iniciar sesión

### Google Calendar
1. Crea credenciales OAuth en [Google Cloud Console](https://console.cloud.google.com/apis/credentials)
2. Habilita la Google Calendar API
3. Actualiza Client ID y Secret en el config de la source
4. Autentícate via OAuth en tu agente

## Agregar un adapter personalizado

¿Quieres agregar soporte para otra herramienta? Crea un nuevo adapter:

1. Crea `skills/daily-standup/adapters/tu-herramienta.md`
2. Sigue el formato de los adapters existentes (ver [notion.md](skills/daily-standup/adapters/notion.md) como referencia)
3. Documenta: source requerida, campos de config, cómo consultar tareas, formato de salida
4. Opcionalmente agrega un template de source en `sources/tu-herramienta/`
5. Envía un PR!

## Contribuir

Las contribuciones son bienvenidas! Algunas ideas:

- **Nuevos adapters de tareas**: Asana, ClickUp, Todoist, Trello, Monday.com
- **Nuevos proveedores de calendario**: Outlook/Microsoft Calendar
- **Nuevos idiomas**: Agregar soporte para más idiomas
- **Mejoras**: Mejor agrupación de commits, resúmenes más inteligentes

## Licencia

[MIT](LICENSE)
