Config = {}

-- General Settings
Config.UseVORP = true
Config.UseMetadata = true
Config.UseDecayItems = true

-- Item Blacklist for storage
Config.ItemBlacklist = {
    "identitycard",
    "passport",
}

-- UI Settings
Config.OpenMenuKey = 0x760A9C6F -- G key
Config.DrawText3D = false
Config.NormalDrawText = true

-- Discord Integration
Config.UseDiscordID = true

-- Job System Settings
Config.UnemployedJobName = "unemployed"
Config.MaxSalary = 150
Config.SalaryTime = 15 -- minutes between salary payments
Config.MaxJobSlots = 5 -- max jobs a player can have
Config.MaxSubJobs = 3 -- max subjobs per main job

-- Auto Bill Collection
Config.AutoCollect = true
Config.AutoCollectJobs = {"doctor", "sheriff", "government"}

-- Duty System
Config.OnDutyCommand = "goonduty"
Config.OffDutyCommand = "offduty"
Config.CheckDutyCommand = "checkduty"
Config.ViewOnDutyCommand = "viewduty"
Config.NoSalaryOffDuty = true
Config.DutyJobs = {"sheriff", "doctor", "government", "marshal"}
Config.OnDutyInstant = true
Config.OnDutyTime = 2.5 -- minutes
Config.AFKOffDutyTimer = 5 -- minutes

-- Alert System
Config.AlertsEnabled = true
Config.AlertCooldown = 60 -- seconds
Config.CancelAlertCommand = "calert"

-- Clan System Settings
Config.ClansEnabled = true
Config.MaxClanSlots = 2  -- Max clans a player can be in at once
Config.MaxClanMembers = 25
Config.ClanCreationCost = 500

-- Clans (configured like Jobs)
Config.Clans = {
    -- Red Chariot Clan
    redchariot = {
        Label = "Red Chariot",
        BossRank = 3,  -- Officer and above can manage
        
        -- Clan Menu Location (Boss Menu)
        ClanMenu = {
            {x = -240.59, y = 769.74, z = 118.08}  -- TODO: Set your clan hideout location
        },
        
        -- Grades (Ranks)
        Grades = {
            [0] = {label = "Initiate", salary = 0},
            [1] = {label = "Member", salary = 10},
            [2] = {label = "Veteran", salary = 20},
            [3] = {label = "Officer", salary = 30},
            [4] = {label = "Commander", salary = 40},
            [5] = {label = "Leader", salary = 50}
        },
        
        -- Storage
        ContainerID = 50,
        ContainerName = "Red Chariot Storage",
        ContainerSlots = 150,
        
        -- Settings
        AllowBilling = false,
        AllowSalary = false
    },
    
    -- Blue Cartsmen Clan
    bluecartsmen = {
        Label = "Blue Cartsmen",
        BossRank = 3,  -- Officer and above can manage
        
        ClanMenu = {
            {x = -275.0, y = 805.0, z = 119.0}  -- TODO: Set your clan hideout location
        },
        
        Grades = {
            [0] = {label = "Recruit", salary = 0},
            [1] = {label = "Cartsman", salary = 10},
            [2] = {label = "Senior Cartsman", salary = 20},
            [3] = {label = "Officer", salary = 30},
            [4] = {label = "Lieutenant", salary = 40},
            [5] = {label = "Leader", salary = 50}
        },
        
        ContainerID = 51,
        ContainerName = "Blue Cartsmen Storage",
        ContainerSlots = 150,
        
        AllowBilling = false,
        AllowSalary = false
    }
}

-- Job Centers (where players can select jobs)
Config.JobCenters = {
    Valentine = {
        Pos = {x = -182.842, y = 629.662, z = 114.08},
        BlipSprite = -272216216,
        Name = 'Job Center',
        ShowBlip = true
    },
}

-- Allowed jobs at job centers
Config.AllowedJobCenterJobs = {
    "doctor",
    "miner",
}

-- Jobs Configuration
Config.Jobs = {
    -- Law Enforcement
    sheriff = {
        Label = "Sheriff Department",
        Pos = {
            {x = -279.21, y = 809.9, z = 119.3}, -- Valentine
            {x = 1361.56, y = -1303.22, z = 77.76}, -- Rhodes
            {x = 2508.43, y = -1308.72, z = 48.95}, -- Saint Denis
            {x = -763.41, y = -1271.52, z = 43.99}, -- Blackwater
        },
        JobMenu = {
            {x = -279.21, y = 809.9, z = 119.3},
            {x = 1361.56, y = -1303.22, z = 77.76},
            {x = 2508.43, y = -1308.72, z = 48.95},
            {x = -763.41, y = -1271.52, z = 43.99},
        },
        BlipSprite = 778811758,
        ShowBlip = true,
        RecruitmentRank = 0,
        BossRank = 6,
        ContainerID = 1,
        ContainerName = "Sheriff Storage",
        ContainerSlots = 100,
        AllowBilling = true,
        AllowSalary = true,
        Webhook = "",
        Grades = {
            [0] = {label = "Recruit", salary = 10},
            [1] = {label = "Deputy", salary = 20},
            [2] = {label = "Officer", salary = 30},
            [3] = {label = "Sergeant", salary = 40},
            [4] = {label = "Lieutenant", salary = 50},
            [5] = {label = "Captain", salary = 60},
            [6] = {label = "Sheriff", salary = 75},
        },
        SubJobs = {
            detective = {
                Label = "Detective",
                RequiredGrade = 2,
                Permissions = {"investigate", "interrogate"}
            },
            marshal = {
                Label = "Marshal",
                RequiredGrade = 4,
                Permissions = {"federal_cases", "cross_border"}
            }
        }
    },

    doctor = {
        Label = "Medical Services",
        Pos = {
            {x = -288.89, y = 808.89, z = 119.38}, -- Valentine
            {x = 2721.72, y = -1225.92, z = 50.36}, -- Saint Denis
            {x = -783.23, y = -1302.62, z = 43.78}, -- Blackwater
        },
        JobMenu = {
            {x = -288.89, y = 808.89, z = 119.38},
            {x = 2721.72, y = -1225.92, z = 50.36},
            {x = -783.23, y = -1302.62, z = 43.78},
        },
        BlipSprite = -592068833,
        ShowBlip = true,
        RecruitmentRank = 0,
        BossRank = 5,
        ContainerID = 2,
        ContainerName = "Medical Storage",
        ContainerSlots = 100,
        AllowBilling = true,
        AllowSalary = true,
        Grades = {
            [0] = {label = "Intern", salary = 15},
            [1] = {label = "Nurse", salary = 25},
            [2] = {label = "Doctor", salary = 40},
            [3] = {label = "Surgeon", salary = 55},
            [4] = {label = "Chief Doctor", salary = 65},
            [5] = {label = "Medical Director", salary = 80},
        },
        SubJobs = {
            surgeon = {
                Label = "Surgeon",
                RequiredGrade = 3,
                Permissions = {"perform_surgery"}
            }
        }
    },

    -- Business Examples
    valgeneral = {
        Label = "Valentine General Store",
        Pos = {
            {x = -321.53, y = 806.85, z = 117.88},
        },
        JobMenu = {
            {x = -321.53, y = 806.85, z = 117.88},
        },
        BlipSprite = 249721687,
        ShowBlip = false,
        RecruitmentRank = 0,
        BossRank = 3,
        ContainerID = 10,
        ContainerName = "Valentine General Store",
        ContainerSlots = 75,
        AllowBilling = true,
        AllowSalary = false,
        Webhook = "",
        Grades = {
            [0] = {label = "Employee", salary = 0},
            [1] = {label = "Clerk", salary = 0},
            [2] = {label = "Manager", salary = 0},
            [3] = {label = "Owner", salary = 0},
        },
        SubJobs = {}
    },

    valstables = {
        Label = "Valentine Stables",
        Pos = {
            {x = -363.64, y = 791.44, z = 116.19},
        },
        JobMenu = {
            {x = -363.64, y = 791.44, z = 116.19},
        },
        BlipSprite = 249721687,
        ShowBlip = false,
        RecruitmentRank = 0,
        BossRank = 3,
        ContainerID = 11,
        ContainerName = "Valentine Stables",
        ContainerSlots = 75,
        AllowBilling = true,
        AllowSalary = false,
        Grades = {
            [0] = {label = "Stable Hand", salary = 0},
            [1] = {label = "Trainer", salary = 0},
            [2] = {label = "Manager", salary = 0},
            [3] = {label = "Owner", salary = 0},
        },
        SubJobs = {}
    },

    miner = {
        Label = "Mining Company",
        Pos = {
            {x = 2920.31, y = 1378.87, z = 56.18},
        },
        JobMenu = {
            {x = 2920.31, y = 1378.87, z = 56.18},
        },
        BlipSprite = 249721687,
        ShowBlip = false,
        RecruitmentRank = 0,
        BossRank = 3,
        ContainerID = 12,
        ContainerName = "Mining Storage",
        ContainerSlots = 50,
        AllowBilling = false,
        AllowBilling = false,
        AllowSalary = false,
        Grades = {
            [0] = {label = "Miner", salary = 0},},
            [2] = {label = "Supervisor", salary = 0},
            [3] = {label = "Mine Boss", salary = 0},
        },
        SubJobs = {}
    },
}

-- Alert System Configuration
Config.Alerts = {
    sheriff = {
        Command = "alertlaw",
        Jobs = {"sheriff", "government"},
        Message = "Law help needed. Check map for coords",
        IsDoctor = false,
        Blip = {
            Sprite = 2119977580,
            Name = 'Law Alert',
        }
    },
    doctor = {
        Command = "alertdoctor",
        Jobs = {"doctor"},
        Message = "Medical help needed. Check map for coords",
        IsDoctor = true,
        Blip = {
            Sprite = 2119977580,
            Name = 'Medical Alert',
        }
    },
}

Config.MedicResponseCommand = "medicresponse"
Config.MedicResponseCommand = "medicresponse"

-- Language Configuration
    -- Job Menu
    JobMenu = "Job Menu",
    ManageEmployees = "Manage Employees",
    ChangingRoom = "Changing Room",
    Outfits = "Outfits",
    NoOutfits = "No saved outfits",
    YourJobIs = "Your job title is: ",
    
    -- Employee Management
    Hire = "Hire",
    Fire = "Fire",
    SetSalary = "Set Salary",
    SetRank = "Set Rank",
    CantFire = "Can't fire yourself",
    CantHire = "Can't hire yourself",
    YouHired = "You hired ",
    YouFired = "You fired ",
    Hired = "You were hired as ",
    Fired = "You were fired from ",
    ChangeRank = "You changed the job rank of ",
    RankChanged = "Your job rank was changed to ",
    CantChangeRank = "You can't change your own rank",
    HighestRank = "You can't rank above or equal to the highest rank, Rank: ",
    ToRank = " to rank: ",
    ListRank = " // Rank: ",
    
    -- Ledger & Salary
    Ledger = "Ledger",
    LedgerCash = "Job Ledger Cash: ",
    DepositCash = "Deposit Cash",
    WithdrawCash = "Withdraw Cash",
    Deposited = "You deposited: ",
    Withdrew = "You withdrew: ",
    Salary = "You received a salary payment of: ",
    MaxSalary = "Cannot exceed max salary of: ",
    SalaryUpdated = "You updated the salary of rank ",
    NoLedgerCash = "Your society ledger doesn't have enough cash to pay salary",
    
    -- Billing
    FineSent = "You sent a bill amount of: ",
    FineReceive = "You received a bill amount of: ",
    Bills = "Your Bills:",
    BillPaid = "You paid a bill amount of: ",
    ViewBills = "View Bills",
    
    -- Inventory
    Inventory = "Inventory",
    InvalidQuantity = "Invalid quantity",
    CantCarry = "You can't carry more items",
    ItemLimit = "You reached the limit for this item",
    MaxSlots = "Can't store more items, slot limit is ",
    
    -- General
    Confirm = "Confirm",
    PlayerID = "Player ID",
    Rank = "Rank",
    Salary = "Salary",
    To = " to ",
    From = " from ",
    InvalidAmount = "Invalid amount",
    NoPlayer = "No person nearby",
    NoCash = "You don't have enough money",
    
    -- Draw Text
    DrawTextJobMenu = "Press G for Job Menu",
    DrawTextJobCenter = "Press G for Job Center",
    
    -- Duty
    YouOnDuty = "You are on duty",
    YouOffDuty = "You are off duty",
    OnDuty = " On Duty",
    OffDuty = " Off Duty",
    ServerID = "Server ID: ",
    AFKOffDuty = "You were taken off duty for being AFK",
    WentOnDuty = "Is on duty",
    WentOffDuty = "Is off duty",
    CantGoOnDuty = "Can't go on duty if hogtied, dead or cuffed",
    
    -- Alerts
    AlertSent = "Alert sent",
    WaitAFew = "Can't spam, wait a few",
    DocOnTheWay = "Doctor is on the way",
    NoDoc = "No doctors available",
    NeedsYourHelp = "Someone needs your help, check your map for a blip",
    
    -- Clans
    ClanMenu = "Clan Menu",
    CreateClan = "Create Clan",
    ClanName = "Clan Name",
    ClanCreated = "Clan created successfully",
    ClanDeleted = "Clan deleted",
    InvitedToClan = "You were invited to ",
    JoinedClan = "You joined ",
    LeftClan = "You left ",
    ClanFull = "Clan is full",
    AlreadyInClan = "Already in a clan",
    NotInClan = "Not in a clan",
    NoPermission = "You don't have permission",
    ClanStorage = "Clan Storage",
    ClanLedger = "Clan Ledger",
    ManageClan = "Manage Clan",
}

