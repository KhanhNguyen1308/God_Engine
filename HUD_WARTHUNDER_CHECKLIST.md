# War Thunder HUD Improvement Checklist

Muc tieu: bien HUD prototype thanh HUD dieu khien Knight theo tinh than War Thunder Tank/Naval: doc nhanh, it chu, uu tien duong ngam, tam ban, huong than/mat phao, trang thai vu khi, radar/sonar va phan hoi ban xa.

## Ket luan tu warthunder_hud.md

- Chon huong `Realistic Battle first`: HUD ho tro do va hien thi, nhung khong tu ngam ban thay nguoi choi.
- Lay Tank lam loi dieu khien: mouse aim dieu khien thap phao/nong, co gioi han goc, toc do quay thap phao gay tre, ban khi dang di chuyen se kem chinh xac.
- Lay Naval lam loi fire-control: tam xa, phao bay vat ly, rangefinder/radar range, thang do tam, splash/bracketing de sua phat ban, tung nhom vu khi/hardpoint co trang thai rieng.
- HUD can giam text: dung reticle, compass, thanh do, icon/trang thai mau; text chi de gia tri can thiet nhu range, reload, ammo, warning.
- Knight khong co crew, nen thay crew panel bang module/status cua robot: core, shield, actuator, leg, sensor, weapon, ammo/energy.

## Da co trong prototype

- [x] Mouse aim cho vu khi: di chuyen chuot thay doi `desired_turret_yaw` va `desired_elevation`; HUD aim marker da chay ca ngang va doc.
- [x] Thap phao/nong co do tre: `turret_yaw` va `barrel_elevation` di chuyen dan toi desired theo toc do gioi han.
- [x] Gioi han goc hardpoint chinh: main gun bi clamp trong cung traverse hien tai.
- [x] Chinh range thu cong bang phim Q/E, charge bang Z/X.
- [x] Dan vat ly bay trong map bang `ArtilleryShell`, khong phai hitscan.
- [x] Co recoil khi ban: nong giat lui bang `_barrel_recoil`.
- [x] Co radar contacts va sonar contacts dua tren bearing/range.
- [x] Co HUD ve reticle trung tam, range ladder, lead scale, weapon strip va sensor scope.
- [x] Co trang thai nang luong, nhiet, jam, shield, speed, base refill.
- [x] Co damage/module co ban: core/shield/weapon/leg/sensor.

## Dang co nhung chua dat chuan War Thunder

- [x] Radar/sonar da co validation bearing co ban va label forward/left/right; van can test cam giac bang viewport khi playtest.
- [ ] Reticle chua duoc calibrate theo dan dao that: range ladder hien chi la do hoa, chua gan chat voi drop/charge/flight time.
- [ ] Lead scale chua dua tren van toc muc tieu va thoi gian bay cua dan.
- [ ] Weapon strip chua tach tung hardpoint/vu khi; hien gan voi main gun va charge chung.
- [ ] Module panel moi la outline don gian, chua co mau hu hong tung module nhu War Thunder.
- [ ] Warning hien bang text nhieu hon icon/mau; can doi sang tin hieu goc man hinh/den canh bao.
- [x] HUD layout da co tinh lai vi tri theo viewport cho module panel, weapon strip, message va sensor scope; van can polish tren nhieu do phan giai.
- [x] Da co gun sight hold bang RMB voi camera zoom/FOV rieng; van can polish scope view nhu War Thunder that.
- [x] Da co top compass hien heading than robot, actual gun bearing, desired aim bearing va contact markers gan nhat.
- [ ] Chua co minimap/objective/capture point layer.

## Chua co

- [ ] Rangefinder/laser/radar range key: do range muc tieu, co sai so va thoi gian quet.
- [ ] Fire-control model tap trung: tinh bearing, range, elevation, projectile flight time, drop, spread, stability.
- [ ] Shell splash/bracketing indicator: hien vi tri phat roi gan/truoc/sau/trai/phai de nguoi choi sua ban.
- [ ] Reload timer theo tung vu khi/hardpoint.
- [ ] Ammo type selector ro rang: energy shell, high-velocity shell, explosive charge/loadout refill.
- [ ] Per-hardpoint traverse/elevation arcs: moi vu khi co gioi han rieng theo mount.
- [ ] Salvo/sequential fire modes cho nhom vu khi.
- [ ] Gun stabilization status: co/khong co stabilize, do lech khi vua di chuyen/vua ban.
- [ ] Turret/gun jam visualization: icon, mau vang/do, delay repair.
- [ ] Damage log/kill feed nho nhu War Thunder.
- [ ] Sensor confidence: contact ro/mo theo radar, sonar, spotter, line-of-sight, jam.
- [ ] Tactical map lon bang phim M.
- [ ] Capture objective HUD: diem A/B/C, thanh capture, team tickets.

## Checklist uu tien lam tiep

### Phase 1 - Chinh xac dieu khien va huong HUD

- [x] Viet test/validation nho cho quy uoc bearing: 0 do = phia truoc robot, +90 = ben phai, -90 = ben trai.
- [x] Sua telemetry heading theo vector forward that cua robot va them nhan huong radar/sonar; can visual playtest them o 0/90/180 do.
- [x] Them top compass: heading than robot, turret/actual gun bearing, desired aim bearing, contact bearing. Objective marker chua co.
- [x] Doi reticle thanh 3 marker rieng: hull forward, desired aim, actual gun aim; desired aim chay ca X/Y theo mouse aim.
- [x] Hien arc gioi han hardpoint tren HUD bang cung trai/phai, doi mau khi chuot vuot gioi han.

### Phase 2 - Fire-control War Thunder Naval

- [ ] Tao `FireControlModel.gd` hoac ham model rieng de tinh range, elevation, charge, muzzle velocity, flight time.
- [ ] Gan range ladder voi dan dao that cua projectile thay vi ve uoc luong.
- [ ] Them rangefinder key: do range contact dang aim, update `measured_range` va sai so.
- [ ] Them flight-time readout nho/icon dong ho gan reticle.
- [ ] Them shell splash memory: 3-5 diem roi gan nhat, hien tren HUD de nguoi choi bracket.

### Phase 3 - Vu khi theo hardpoint

- [ ] Tao data cho hardpoint: ten, arc yaw, arc elevation, reload, ammo type, heat, jam, selected.
- [ ] Tach main cannon, secondary gun, melee/arm thanh cac slot hien tren weapon strip.
- [ ] Mouse aim dieu khien hardpoint dang selected; hardpoint khac co the follow/hold fire theo mode.
- [ ] Reload va heat hien bang ring/bar nho theo tung hardpoint.
- [ ] Ban theo mode single/salvo/sequential neu co nhieu nong.

### Phase 4 - Readability va phong cach

- [ ] Giam text tren HUD xuong muc can thiet: RNG, EL, AZ, ammo, reload, warning.
- [ ] Dung line art mong, mau xanh la/cyan/amber do vua phai, nen trong suot; tranh panel lon day chu.
- [ ] Chuyen warning sang icon/mau/nhap nhay: JAM, HEAT, SHIELD LOW, SENSOR LOST.
- [ ] Lam module silhouette ro hon: core, shield, legs, sensor mast, weapon mount.
- [ ] Kiem tra HUD tren 1280x720 va 1920x1080, khong overlap, khong che reticle.

## Mapping sang file hien tai

- `scripts/KnightController.gd`: dieu khien robot, aim, fire, projectile spawn, radar/sonar telemetry.
- `scripts/PrototypeHUD.gd`: HUD hien tai, can tach bot logic ve fire-control model va ve lai layout.
- `scripts/SensorScope.gd`: radar/sonar scope hien tai, can validation truc huong va style pass.
- `scripts/ArtilleryShell.gd`: projectile vat ly, can them impact report/splash event.
- `scripts/DamageableTarget.gd`: target/damage, can them contact velocity va impact feedback.

## Definition of Done cho lan cai tien HUD tiep theo

- Mouse len/xuong lam nong len/xuong thay doi ro rang trong 3D va reticle.
- Radar/sonar dung huong khi robot quay, co marker forward ro rang.
- HUD co compass tren cung, reticle trung tam, weapon strip duoi, module status trai, sensor phai.
- Range ladder va elevation phan anh dan dao that it nhat o 3 moc range: gan, trung, xa.
- Khi ban xa, nguoi choi thay duoc shell bay/recoil/impact hoac splash marker de sua phat tiep theo.

## Completed Phase 1 upgrade - 2026-07-20

- [x] `KnightController.gd`: heading now comes from the real forward vector, display azimuth uses player-facing convention: right positive, left negative.
- [x] `PrototypeHUD.gd`: added top compass, hull/actual/desired aim markers, clearer hardpoint arc, viewport-aware HUD placement.
- [x] `SensorScope.gd`: added FWD/L/R labels to radar and sonar displays.
- [x] `tests/smoke_test.gd`: added bearing convention validation.
- [ ] Still needs visual playtest screenshot pass: confirm HUD readability and radar/sonar feel in an actual rendered viewport, not only headless.

## Superseded aim-sight fix - 2026-07-20

These entries were superseded by `Completed aiming reset - 2026-07-20`.

- [x] Fixed HUD aim marker only moving horizontally: desired aim now offsets by azimuth and elevation delta.
- [x] Added `aim_sight` input action on RMB, with hold-to-sight camera zoom.
- [x] Added smoke-test regression for mouse vertical aim and sight activation/release.
- [ ] Still needs human visual playtest: confirm the sight feels like War Thunder tank aiming at real framerate.

## Superseded aim model correction - 2026-07-20

These entries were superseded by `Completed aiming reset - 2026-07-20`.

- [x] Replaced bad floating-aim HUD model with War Thunder-style mouse aim: screen center is commanded aim, gun marker lags behind.
- [x] Replaced RMB cockpit zoom with a dedicated gun sight camera that follows desired yaw/elevation.
- [x] Smoke test now asserts dedicated sight camera activation and desired yaw/elevation tracking.
- [ ] Needs real viewport playtest for feel: camera pitch sign, sensitivity, and marker scale may still need tuning.

## Superseded reticle offset correction - 2026-07-20

These entries were superseded by `Completed aiming reset - 2026-07-20`.

- [x] `AIM` reticle no longer stays at screen center; mouse motion moves it within a clamped screen box.
- [x] `GUN` marker now lags relative to the moving `AIM` reticle.
- [x] Telemetry exposes `aim_screen_offset` and smoke test asserts it moves after mouse input.
- [ ] Needs real viewport tuning: reticle box size, sensitivity, and whether RMB should recentre or keep offset.

## Completed range-dial fire-control fix - 2026-07-20

- [x] Q/E range dial now calls `_sync_elevation_to_range()` and changes `desired_elevation`.
- [x] Charge changes now recompute the range/elevation solution.
- [x] Projectile launch speed and range/elevation calculation now share `_muzzle_speed_for_charge()`.
- [x] Smoke test asserts range dial increases desired elevation and visible barrel pitch follows barrel elevation.
- [ ] Needs visual playtest: confirm elevation movement is obvious enough from chase and gun-sight views.

## Completed aiming reset - 2026-07-20

- [x] Removed the wrong `aim_screen_offset` floating-reticle model.
- [x] Mouse now directly changes desired turret yaw and desired barrel elevation only.
- [x] RMB gun sight camera follows actual turret/barrel angles, not desired aim.
- [x] Q/E range zeroing now adds ballistic elevation delta without replacing manual mouse elevation.
- [x] HUD reticle simplified to sight center plus a small actual/desired lag cue.
