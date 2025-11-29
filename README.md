# Ouro Society - Advanced Job & Clan System

A comprehensive multijob, subjob, and clan management system for RedM servers using VORP Core.

## Features

### Job System
- **Multijob Support**: Players can have multiple jobs simultaneously (configurable max jobs)
- **SubJob System**: Each main job can have specialized subjobs with unique permissions
- **Dynamic Job Switching**: Players can switch between their active jobs
- **Job Centers**: Configurable job centers where players can select jobs
- **Boss Menus**: Full job management for bosses (hire, fire, set ranks, manage salaries)
- **Society Ledgers**: Each job has a ledger for managing society funds
- **Job Storage**: Integrated with VORP inventory for job-specific storage containers
- **Billing System**: Jobs can bill players for services
- **Salary System**: Automated salary payments from society ledgers
- **Duty System**: Optional duty system for specific jobs (law enforcement, medical, etc.)
- **Grade/Rank System**: Fully configurable ranks with custom labels and salaries

### Clan System
- **Clan Creation**: Players can create clans with custom names
- **Clan Ranks**: 5 default ranks (Member, Veteran, Officer, Co-Leader, Leader)
- **Clan Ledger**: Shared clan bank account
- **Clan Storage**: Shared inventory system for clan members
- **Member Management**: Invite, kick, and promote members
- **Ownership Transfer**: Leaders can transfer ownership
### UI Features
- Job center interface for job selection
- Boss menu for employee management
- Configurable colors and themes
- Responsive design

## Installation

### 1. Database Setup
Run the SQL file to create all necessary tables:
```sql
-- Execute: sql/society.sql
```

This creates the following tables:
- `ouro_society` - Job grades and salaries
- `ouro_society_ledger` - Job ledger balances
- `ouro_container` - Job storage containers
- `ouro_bills` - Billing system
- `ouro_player_jobs` - Player job assignments (multijob)
- `ouro_player_subjobs` - Player subjob assignments
- `ouro_clans` - Clan data
- `ouro_clan_members` - Clan membership
- `ouro_clan_ledger` - Clan bank accounts
- `ouro_clan_storage` - Clan storage
- `ouro_duty_status` - Duty tracking

### 2. Resource Installation
1. Place `Ouro_Society` folder in your `resources/[OURO]` directory
2. Add to your `server.cfg`:
```
ensure Ouro_Society
```

### 3. Dependencies
Required:
- `vorp_core`
- `vorp_inventory`
- `oxmysql`

## Configuration

### Main Config (`config/config.lua`)

#### Job System Settings
```lua
Config.MaxJobSlots = 5          -- Max jobs per player
Config.MaxSubJobs = 3            -- Max subjobs per main job
Config.MaxSalary = 150           -- Maximum salary allowed
Config.SalaryTime = 15           -- Minutes between salary payments
Config.UnemployedJobName = "unemployed"
```

#### Duty System
```lua
Config.DutyJobs = {"sheriff", "doctor", "government"}
Config.NoSalaryOffDuty = true    -- Don't pay salary when off duty
Config.OnDutyCommand = "goonduty"
Config.OffDutyCommand = "offduty"
```

#### Clan System
```lua
Config.ClansEnabled = true
Config.MaxClanMembers = 25
Config.ClanCreationCost = 500
```

### Adding Jobs

Edit `config/config.lua` and add to `Config.Jobs`:

```lua
myjob = {
    Label = "My Job Name",
    Pos = {
        {x = 100.0, y = 200.0, z = 50.0}, -- Location 1
        {x = 150.0, y = 250.0, z = 55.0}, -- Location 2
    },
    JobMenu = {
        {x = 100.0, y = 200.0, z = 50.0}, -- Boss menu location
    },
    BlipSprite = 249721687,
    ShowBlip = true,
    RecruitmentRank = 0,     -- Minimum rank to hire
    BossRank = 3,            -- Rank with full permissions
    ContainerID = 20,        -- Unique storage ID
    ContainerName = "My Job Storage",
    AllowBilling = true,
    AllowSalary = true,
    Grades = {
        [0] = {label = "Employee", salary = 10},
        [1] = {label = "Senior", salary = 20},
        [2] = {label = "Manager", salary = 30},
        [3] = {label = "Boss", salary = 40},
    },
    SubJobs = {
        specialist = {
            Label = "Specialist",
            RequiredGrade = 1,
            Permissions = {"special_task", "advanced_access"}
        }
    }
}
```

### Adding Jobs to Job Center

1. Add job to `Config.AllowedJobCenterJobs`:
```lua
Config.AllowedJobCenterJobs = {
    "doctor",
    "miner",
    "myjob",  -- Add your job
}
```

2. Add job to NUI config (`html/configNui.js`):
```javascript
jobs: [
    {
        "title": "My Job",
        "shortDescription": "Short description here",
        "description": "Longer description of the job...",
        "group": "myjob",  -- Must match config.lua job name
        "whitelisted": false,
        "iconName": "myjob.png",
        requirements: ["Requirement 1", "Requirement 2"]
    }
]
```

3. Add job icon to `html/assets/images/` (PNG format, recommended 128x128px)

## Usage

### Commands

#### Job Management
- `/switchjob [jobname]` - Switch your active job
- `/bill [playerid] [amount]` - Bill a player (requires billing permission)

#### Duty System
- `/goonduty` - Go on duty
- `/offduty` - Go off duty
- `/checkduty` - Check your duty status
- `/viewduty [jobname]` - View who is on duty (boss only)

#### Alerts
- `/alertlaw` - Send alert to law enforcement
- `/alertdoctor` - Send alert to doctors
- `/calert` - Cancel your alert

### Boss Menu
1. Go to a job menu location (configured in `Config.Jobs[jobname].JobMenu`)
2. Press `G` to open the menu
3. Available options:
   - **Manage Employees**: Hire, fire, set ranks
   - **Ledger**: Deposit/withdraw society funds
   - **Inventory**: Access job storage
   - **View Bills**: See pending bills
   - **Toggle Duty**: Go on/off duty (if applicable)

### Employee Management
As a boss, you can:
- **Hire Players**: Add nearby players to your job
- **Fire Players**: Remove employees
- **Set Ranks**: Promote/demote employees
- **Set Salaries**: Configure salary for each rank (up to max)

### Ledger Management
- **Deposit**: Add money from your personal cash to society ledger
- **Withdraw**: Take money from society ledger (boss only)
- **View Balance**: Check current society balance
- Salaries are automatically paid from the ledger if enabled

### Clan System

#### Creating a Clan
Use the clan creation command or menu (costs $500 by default)

#### Clan Management
- Invite players to join
- Promote/demote members
- Kick members (requires Officer rank or higher)
- Access clan storage
- Manage clan ledger
- Transfer ownership
- Delete clan (owner only)

#### Clan Ranks
- **0**: Member (basic access)
- **1**: Veteran (basic access)
- **2**: Officer (can invite, kick lower ranks, access ledger)
- **3**: Co-Leader (all Officer perms + more)
- **4**: Leader (full control)

## Exports

### Server Exports

```lua
-- Get society ledger balance
exports['Ouro_Society']:GetSocietyLedger(jobName)

-- Update society ledger (returns success, result)
exports['Ouro_Society']:UpdateSocietyLedger(jobName, amount, operation)
-- operation: "add", "remove", or "set"

-- Check if player is on duty
exports['Ouro_Society']:IsPlayerOnDuty(source, jobName)

-- Get clan data
exports['Ouro_Society']:GetClanData(clanId)

-- Get clan members
exports['Ouro_Society']:GetClanMembers(clanId)

-- Check if player is in a clan
exports['Ouro_Society']:IsPlayerInClan(charIdentifier)
```

## Integration with VORP

### Job Storage
Job storage integrates directly with VORP Inventory v4.0+:
- Uses VORP's container system
- Supports item decay
- Item blacklist support
- Max slot configuration

### Character Data
- Reads from VORP character data
- Uses VORP job system
- Integrates with VORP money system
- Discord ID tracking (if enabled)

### Multijob System
The multijob system extends VORP's native job system:
- Primary job syncs with VORP's character.job
- Additional jobs stored in `ouro_player_jobs`
- Switch between jobs with `/switchjob` command
- Active job determines VORP job

## Troubleshooting

### Jobs Not Showing in Job Center
1. Check `Config.AllowedJobCenterJobs` includes the job
2. Verify job exists in `html/configNui.js`
3. Ensure job icon exists in `html/assets/images/`

### Boss Menu Not Opening
1. Check you're at a configured `JobMenu` location
2. Verify your job grade is at or above `BossRank`
3. Check console for errors

### Salary Not Paying
1. Verify `AllowSalary = true` in job config
2. Check society ledger has sufficient funds
3. If duty-enabled job, ensure player is on duty
4. Check salary is set in database (`ouro_society` table)

### Storage Not Opening
1. Verify `ContainerID` is unique for each job
2. Check container exists in `ouro_container` table
3. Ensure VORP Inventory is running

## Credits

- **Framework**: VORP Core
- **Developed by**: Ouro Development

## Support

For support, join our Discord or submit an issue on GitHub.

## License

All rights reserved. This is a custom resource for your RedM server.

## Credits

- **Framework**: VORP Core
- **UI Design & Base Architecture**: Inspired by VORP framework and Syn development team
- **Developed by**: Ouro Development