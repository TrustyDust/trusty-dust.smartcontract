# TrustyDust Smart Contract Notes (Simplified Stack)

## Struktur Proyek (src/)
- `DustToken.sol` — ERC20 non-transferable, Role {OWNER, OPERATOR, SYSTEM}; only OPERATOR can mint/burn; `_update` blokir transfer user↔user.
- `Identity.sol` — Registry `users[address] -> SharedTypes.User` (trustScore, tier, reputation, posts, jobsCompleted, hasBadge). Fungsi mutasi tanpa ACL: addTrust, setTier (set hasBadge=true), addReputation, addPost, addJobCompleted.
- `Core.sol` — Reward sosial & job (LIKE/COMMENT/REPOST, rating 1-5) membayar dalam DUST + update Identity.trustScore/jobsCompleted; tidak ada role check.
- `Content.sol` — `mintPost()` membakar 10 DUST dari caller lalu increment posts di Identity.
- `Jobs.sol` — Job board simpel: create burns 10 DUST fee, status {OPEN, COMPLETED, CANCELLED}, poster assign worker, approve triggers Core.rewardJob, cancel closes job. `minScore` hanya disimpan; tidak ada gating check.
- `Verifier.sol` — Pembungkus verifier eksternal (alamat dapat diset). `verifyTrustScore` dan `verifyTier`; tier success menulis `identity.setTier`.
- `SharedTypes.sol` — Enum SocialAction, JobStatus; struct User, Job.
- `Errors.sol` — Custom errors: Unauthorized, ZeroAddress, ZeroAmount, InvalidInput, InvalidState, InsufficientBalance.

## Peta Kontrak & Dependensi
- DustToken ← digunakan oleh Core (mint), Content (burn), Jobs (burn), dan harus diberi role OPERATOR ke kontrak tersebut.
- Identity ← di-update oleh Core (trust & jobsCompleted), Content (posts), Jobs (none langsung), Verifier (tier/hasBadge).
- Core ← dipanggil Jobs.approveJob (reward worker) dan langsung oleh backend untuk reward sosial.
- Content ← standalone; hanya butuh akses burn ke DustToken.
- Jobs ← butuh DustToken (burn fee) + Core (reward job). Identity dibaca melalui Core saja.
- Verifier ← butuh external verifier addresses; menulis tier ke Identity.

## Flow Ringkas
- Social reward: `Core.rewardSocial(user, action)` → pilih delta (1/3/1 DUST) → Identity.addTrust → DustToken.mint.
- Job reward: `Jobs.createJob` burn 10 DUST; `Jobs.assignWorker`; `Jobs.approveJob` (poster only) sets COMPLETED + Core.rewardJob(worker, rating) → mint DUST + update trust + jobsCompleted.
- Content: `mintPost` burn 10 DUST → Identity.addPost.
- Verifikasi: `verifyTier`/`verifyTrustScore` memanggil verifier eksternal; pada tier sukses Identity.setTier + hasBadge.

## Catatan Peran & Risiko
- DustToken adalah satu-satunya kontrol akses (Role). Pastikan Core/Content/Jobs punya role OPERATOR sebelum produksi.
- Identity dapat dimodifikasi oleh siapa saja (tidak ada ACL) sesuai kode saat ini—ketahui implikasinya untuk kepercayaan data.
- Jobs tidak memeriksa minScore saat apply/assign; hanya menyimpan nilai. Tambah check off-chain atau perlu hardening di masa depan.
- Verifier tidak memakai signature/owner guard untuk `setVerifiers`; siapa saja bisa mengubah alamat verifier saat ini.

## Build/Test/Deploy
- Build: `forge build`
- Test: `forge test`
- Deploy script: `script/Deploy.s.sol` (deploy semua kontrak + set role OPERATOR ke Core/Content/Jobs).
