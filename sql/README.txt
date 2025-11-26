=====================================
OURO SOCIETY - SQL INSTALLATION GUIDE
=====================================

Run these SQL files in order:

1. society.sql
   - Creates all job-related tables
   - Includes seed data for default jobs (sheriff, doctor, etc.)
   
2. clans.sql
   - Creates all clan-related tables
   - Includes seed data for configured clans (redchariot, bluecartsmen)

=====================================
TABLES CREATED
=====================================

JOB SYSTEM:
- ouro_society (job grades and salaries)
- ouro_society_ledger (job bank accounts)
- ouro_player_jobs (multi-job system)
- ouro_player_subjobs (subjob system)
- ouro_container (storage containers)
- ouro_bills (billing system)
- ouro_duty_status (on/off duty tracking)

CLAN SYSTEM:
- ouro_clans (clan grades and salaries)
- ouro_clan_ledger (clan bank accounts)
- ouro_player_clans (multi-clan system, max 2)

=====================================
NOTES
=====================================

- Jobs are configured in config/config.lua
- Clans are configured in config/config.lua
- Both systems work identically
- Players can have multiple jobs and up to 2 clans
- Use /job command to manage jobs
- Use /clan command to manage clans

