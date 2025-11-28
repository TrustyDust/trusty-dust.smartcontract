src/
│
├── DustToken.sol       # ERC20 non-transferable with Role {OWNER, OPERATOR, SYSTEM}
├── Identity.sol        # Registry of users (trustScore, tier, reputation, posts, jobsCompleted, hasBadge)
├── Core.sol            # Reward logic for social actions and job ratings; mints DUST + updates Identity
├── Content.sol         # Burns 10 DUST to record a post in Identity
├── Jobs.sol            # Simple job board: create burns 10 DUST; assign/approve/cancel; rewards via Core
├── Verifier.sol        # External verifier wrapper; can set verifiers; successful tier writes to Identity
├── SharedTypes.sol     # Enums (SocialAction, JobStatus) and structs (User, Job)
└── Errors.sol          # Custom errors (Unauthorized, ZeroAddress, ZeroAmount, InvalidInput, InvalidState, InsufficientBalance)
