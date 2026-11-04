# EPMS W1-D3 + W2 interface verification (against 8081)
# ASCII-only on purpose: Windows PowerShell 5.1 misreads UTF-8 .ps1 without BOM.
$ErrorActionPreference = 'Stop'
$Base = 'http://localhost:8081/api/v1'
$script:pass = 0
$script:fail = 0

function Call-Api {
    param(
        [string]$Method,
        [string]$Path,
        [hashtable]$Headers = @{},
        [object]$Body = $null,
        [string]$ContentType = 'application/json'
    )
    $params = @{ Uri = "$Base$Path"; Method = $Method; Headers = $Headers; ContentType = $ContentType; UseBasicParsing = $true }
    if ($null -ne $Body) {
        $params.Body = if ($Body -is [string]) { $Body } else { ($Body | ConvertTo-Json -Depth 6 -Compress) }
    }
    try {
        $resp = Invoke-WebRequest @params
        return [pscustomobject]@{ Http = [int]$resp.StatusCode; Json = ($resp.Content | ConvertFrom-Json) }
    } catch {
        $r = $_.Exception.Response
        if ($null -ne $r) {
            $reader = New-Object System.IO.StreamReader($r.GetResponseStream())
            $text = $reader.ReadToEnd()
            $json = $null
            try { $json = $text | ConvertFrom-Json } catch {}
            return [pscustomobject]@{ Http = [int]$r.StatusCode; Json = $json }
        }
        return [pscustomobject]@{ Http = 0; Json = $null; Error = $_.Exception.Message }
    }
}

function Check {
    param([string]$Name, [object]$Actual, [object]$Expected)
    [decimal]$numA = 0
    [decimal]$numE = 0
    $ok = $false
    if ([decimal]::TryParse("$Actual", [ref]$numA) -and [decimal]::TryParse("$Expected", [ref]$numE)) {
        $ok = ($numA -eq $numE)
    } else {
        $ok = ("$Actual" -eq "$Expected")
    }
    if ($ok) { $script:pass++ } else { $script:fail++ }
    $flag = if ($ok) { 'PASS' } else { 'FAIL' }
    Write-Output ("[{0}] {1} | actual={2} expected={3}" -f $flag, $Name, $Actual, $Expected)
}

function Code { param($Resp) return $Resp.Json.code }
# Windows PowerShell 5.1 decodes UTF-8 JSON as Latin-1; convert back so Chinese messages are readable
function Fix-Text {
    param($s)
    if (-not $s) { return $s }
    $bytes = [System.Text.Encoding]::GetEncoding(28591).GetBytes([string]$s)
    return [System.Text.Encoding]::UTF8.GetString($bytes)
}
function Msg  { param($Resp) return (Fix-Text $Resp.Json.message) }

Write-Output '===== 0. Login ====='
$adminLogin = Call-Api POST '/auth/login' @{} @{ username = 'admin'; password = 'Epms@123456' }
Check 'admin login code' (Code $adminLogin) 0
$adminToken = $adminLogin.Json.data.accessToken

$hrLogin = Call-Api POST '/auth/login' @{} @{ username = 'hr01'; password = 'Epms@123456' }
Check 'hr01 login code' (Code $hrLogin) 0
$hrToken = $hrLogin.Json.data.accessToken

$empLogin = Call-Api POST '/auth/login' @{} @{ username = 'employee01'; password = 'Epms@123456' }
Check 'employee01 login code' (Code $empLogin) 0
$empToken = $empLogin.Json.data.accessToken

$e4Login = Call-Api POST '/auth/login' @{} @{ username = 'e1004'; password = 'Epms@123456' }
Check 'e1004 login code' (Code $e4Login) 0
$e4Token = $e4Login.Json.data.accessToken

$hAdmin = @{ Authorization = "Bearer $adminToken" }
$hHr    = @{ Authorization = "Bearer $hrToken" }
$hEmp   = @{ Authorization = "Bearer $empToken" }
$hE4    = @{ Authorization = "Bearer $e4Token" }

Write-Output ''
Write-Output '===== A. W1-D3 ten fixes ====='
Write-Output '--- 1. disable user kicks session ---'
Check 'admin disable e1004 code' (Code (Call-Api POST '/system/users/8/status?status=0' $hAdmin $null)) 0
$r = Call-Api GET '/auth/me' $hE4
Check 'old token after disable code' (Code $r) 40102
Check 'admin re-enable e1004 code' (Code (Call-Api POST '/system/users/8/status?status=1' $hAdmin $null)) 0

Write-Output '--- 2/3/4. employee blocked on user/dept/role apis ---'
Check 'employee GET /system/users code' (Code (Call-Api GET '/system/users' $hEmp)) 40300
# /system/depts/tree is intentionally open to every logged-in user (dropdown data source)
Check 'employee GET /system/depts/tree code (open by design)' (Code (Call-Api GET '/system/depts/tree' $hEmp)) 0
Check 'employee GET /system/depts code' (Code (Call-Api GET '/system/depts' $hEmp)) 40300
Check 'employee GET /system/roles code' (Code (Call-Api GET '/system/roles' $hEmp)) 40300
Check 'admin GET /system/users code' (Code (Call-Api GET '/system/users' $hAdmin)) 0

Write-Output '--- 5. pagination validation ---'
$r = Call-Api GET '/system/users?pageNum=0' $hAdmin
Check 'pageNum=0 code' (Code $r) 40001
Write-Output ("       message = " + (Msg $r))
$r = Call-Api GET '/system/users?pageSize=999' $hAdmin
Check 'pageSize=999 code' (Code $r) 40001
Write-Output ("       message = " + (Msg $r))
Check 'pageSize=201 code' (Code (Call-Api GET '/system/users?pageSize=201' $hAdmin)) 40001
Check 'normal page code' (Code (Call-Api GET '/system/users?pageNum=1&pageSize=10' $hAdmin)) 0

Write-Output '--- 6. invalid refresh token ---'
$r = Call-Api POST '/auth/refresh' @{} @{ refreshToken = 'not-a-valid-token' }
Check 'invalid refreshToken code' (Code $r) 40101

Write-Output '--- 7. user list batch query (N+1 removed) ---'
$r = Call-Api GET '/system/users?pageNum=1&pageSize=10' $hAdmin
Check 'user list size' $r.Json.data.list.Count 10
Check 'user list role filled' ([bool]$r.Json.data.list[0].roles) 'True'

Write-Output '--- 10. login error differentiation ---'
$r = Call-Api POST '/auth/login' @{} @{ username = 'admin'; password = 'wrong-password' }
Check 'wrong password code' (Code $r) 40100
Write-Output ("       message = " + (Msg $r))
$r = Call-Api POST '/auth/login' @{} @{ username = 'no-such-user'; password = 'Epms@123456' }
Check 'unknown user code' (Code $r) 40100
Check 'admin disable e1004 code' (Code (Call-Api POST '/system/users/8/status?status=0' $hAdmin $null)) 0
$r = Call-Api POST '/auth/login' @{} @{ username = 'e1004'; password = 'Epms@123456' }
Check 'disabled account code' (Code $r) 40300
Write-Output ("       message = " + (Msg $r))
Check 'admin re-enable e1004 code' (Code (Call-Api POST '/system/users/8/status?status=1' $hAdmin $null)) 0

Write-Output ''
Write-Output '===== B. W2 cycles ====='
$r = Call-Api GET '/perf/cycles?pageNum=1&pageSize=10' $hAdmin
Check 'cycle total' (Code $r) 0
Check 'cycle total=4' $r.Json.data.total 4
Check 'cycle list count=4' $r.Json.data.list.Count 4
Check 'keyword 2026 total=2' (Call-Api GET '/perf/cycles?keyword=2026' $hAdmin).Json.data.total 2
Check 'status IN_PROGRESS total=1' (Call-Api GET '/perf/cycles?status=IN_PROGRESS' $hAdmin).Json.data.total 1
Check 'status CLOSED total=2' (Call-Api GET '/perf/cycles?status=CLOSED' $hAdmin).Json.data.total 2
Check 'status DRAFT total=1' (Call-Api GET '/perf/cycles?status=DRAFT' $hAdmin).Json.data.total 1
Check 'cycle pageNum=0 code' (Code (Call-Api GET '/perf/cycles?pageNum=0' $hAdmin)) 40001
Check 'cycle pageSize=999 code' (Code (Call-Api GET '/perf/cycles?pageSize=999' $hAdmin)) 40001

Write-Output '--- CRUD + state machine ---'
$newCycle = @{
    cycleCode = '2026-Q3'; cycleName = '2026 Q3 cycle'; cycleType = 'QUARTER'
    startDate = '2026-07-01'; endDate = '2026-09-30'
    selfDeadline = '2026-09-20 23:59:59'; managerDeadline = '2026-09-25 23:59:59'
    hrDeadline = '2026-09-28 23:59:59'; finalDeadline = '2026-09-30 23:59:59'
    remark = 'created by verify script'
}
$r = Call-Api POST '/perf/cycles' $hAdmin $newCycle
Check 'create cycle code' (Code $r) 0
Check 'created status=DRAFT' $r.Json.data.status 'DRAFT'
$newId = $r.Json.data.id
Check 'duplicate code create' (Code (Call-Api POST '/perf/cycles' $hAdmin $newCycle)) 40902

$badDate = @{
    cycleCode = '2026-BAD'; cycleName = 'bad date'; cycleType = 'QUARTER'
    startDate = '2026-09-30'; endDate = '2026-07-01'
    selfDeadline = '2026-09-20 23:59:59'; managerDeadline = '2026-09-25 23:59:59'
    hrDeadline = '2026-09-28 23:59:59'; finalDeadline = '2026-09-30 23:59:59'
}
$r = Call-Api POST '/perf/cycles' $hAdmin $badDate
Check 'end before start rejected' (Code $r) 40001

$badOrder = @{
    cycleCode = '2026-BAD2'; cycleName = 'deadline order bad'; cycleType = 'QUARTER'
    startDate = '2026-07-01'; endDate = '2026-09-30'
    selfDeadline = '2026-09-25 23:59:59'; managerDeadline = '2026-09-20 23:59:59'
    hrDeadline = '2026-09-28 23:59:59'; finalDeadline = '2026-09-30 23:59:59'
}
$r = Call-Api POST '/perf/cycles' $hAdmin $badOrder
Check 'deadline order violated rejected' (Code $r) 40001

$outOfRange = @{
    cycleCode = '2026-BAD3'; cycleName = 'deadline out of range'; cycleType = 'QUARTER'
    startDate = '2026-07-01'; endDate = '2026-09-30'
    selfDeadline = '2026-08-20 23:59:59'; managerDeadline = '2026-08-25 23:59:59'
    hrDeadline = '2026-08-28 23:59:59'; finalDeadline = '2026-10-05 23:59:59'
}
$r = Call-Api POST '/perf/cycles' $hAdmin $outOfRange
Check 'deadline outside cycle rejected' (Code $r) 40001
Write-Output ("       message = " + (Msg $r))

$r = Call-Api PUT "/perf/cycles/$newId" $hAdmin @{ cycleCode = '2026-Q3'; cycleName = '2026 Q3 cycle v2'; status = 'CLOSED' }
Check 'update with status=CLOSED code' (Code $r) 0
Check 'status still DRAFT (bypass blocked)' $r.Json.data.status 'DRAFT'

$r = Call-Api POST "/perf/cycles/$newId/publish" $hAdmin $null
Check 'publish code' (Code $r) 0
Check 'status after publish' $r.Json.data.status 'IN_PROGRESS'
Check 'republish rejected' (Code (Call-Api POST "/perf/cycles/$newId/publish" $hAdmin $null)) 40900
Check 'edit published rejected' (Code (Call-Api PUT "/perf/cycles/$newId" $hAdmin @{ cycleCode = '2026-Q3'; cycleName = 'x' })) 40900

$r = Call-Api POST "/perf/cycles/$newId/close" $hAdmin $null
Check 'close code' (Code $r) 0
Check 'status after close' $r.Json.data.status 'CLOSED'
Check 'close twice rejected' (Code (Call-Api POST "/perf/cycles/$newId/close" $hAdmin $null)) 40900
Check 'delete closed rejected' (Code (Call-Api DELETE "/perf/cycles/$newId" $hAdmin $null)) 40900

Write-Output '--- closed cycle blocks new perf record ---'
$r = Call-Api GET '/perf/cycles/1/can-add-record' $hAdmin
Check 'CLOSED cycle allowed' $r.Json.data.allowed 'False'
Check 'CLOSED cycle reason not empty' ([bool]$r.Json.data.reason) 'True'
Write-Output ("       reason = " + (Fix-Text $r.Json.data.reason))
$r = Call-Api GET '/perf/cycles/2/can-add-record' $hAdmin
Check 'IN_PROGRESS cycle allowed' $r.Json.data.allowed 'True'

Write-Output '--- logical delete releases unique code ---'
$draft = @{
    cycleCode = '2026-DEL'; cycleName = 'to be deleted'; cycleType = 'QUARTER'
    startDate = '2026-10-01'; endDate = '2026-12-31'
    selfDeadline = '2026-12-20 23:59:59'; managerDeadline = '2026-12-25 23:59:59'
    hrDeadline = '2026-12-28 23:59:59'; finalDeadline = '2026-12-31 23:59:59'
}
$r = Call-Api POST '/perf/cycles' $hAdmin $draft
Check 'create draft code' (Code $r) 0
$delId = $r.Json.data.id
Check 'delete draft code' (Code (Call-Api DELETE "/perf/cycles/$delId" $hAdmin $null)) 0
Check 'recreate same code' (Code (Call-Api POST '/perf/cycles' $hAdmin $draft)) 0

Write-Output ''
Write-Output '===== C. W2 indicator library ====='
$r = Call-Api GET '/perf/indicators?pageNum=1&pageSize=20' $hAdmin
Check 'indicator total=12' $r.Json.data.total 12
Check 'indicator list count=12' $r.Json.data.list.Count 12
Check 'cat PERFORMANCE=5' (Call-Api GET '/perf/indicators?bizCategory=PERFORMANCE' $hAdmin).Json.data.total 5
Check 'cat ABILITY=4' (Call-Api GET '/perf/indicators?bizCategory=ABILITY' $hAdmin).Json.data.total 4
Check 'cat ATTITUDE=3' (Call-Api GET '/perf/indicators?bizCategory=ATTITUDE' $hAdmin).Json.data.total 3
Check 'indicator pageNum=0 code' (Code (Call-Api GET '/perf/indicators?pageNum=0' $hAdmin)) 40001
Check 'indicator pageSize=999 code' (Code (Call-Api GET '/perf/indicators?pageSize=999' $hAdmin)) 40001

Write-Output '--- create then query immediately ---'
$newInd = @{
    indicatorCode = 'TEST-W2-01'; indicatorName = 'verify test indicator'; bizCategory = 'PERFORMANCE'
    scoringType = 'QUANTITATIVE'; unit = 'pcs'; defaultWeight = 6.5; defaultFactorCode = 'F1'
    dataSource = 'verify script'; scoringDesc = 'verify only'
}
$r = Call-Api POST '/perf/indicators' $hAdmin $newInd
Check 'create indicator code' (Code $r) 0
$r = Call-Api GET '/perf/indicators?keyword=TEST-W2-01' $hAdmin
Check 'query new indicator total=1' $r.Json.data.total 1
Check 'new indicator weight=6.5' ([decimal]$r.Json.data.list[0].defaultWeight) 6.5
Check 'duplicate indicator code' (Code (Call-Api POST '/perf/indicators' $hAdmin $newInd)) 40902
Check 'negative weight rejected' (Code (Call-Api POST '/perf/indicators' $hAdmin @{
    indicatorCode = 'TEST-NEG'; indicatorName = 'neg weight'; bizCategory = 'ABILITY'
    scoringType = 'QUALITATIVE'; unit = 'pt'; defaultWeight = -5; defaultFactorCode = 'F2'
})) 40001
Check 'weight 150 rejected' (Code (Call-Api POST '/perf/indicators' $hAdmin @{
    indicatorCode = 'TEST-BIG'; indicatorName = 'big weight'; bizCategory = 'ABILITY'
    scoringType = 'QUALITATIVE'; unit = 'pt'; defaultWeight = 150; defaultFactorCode = 'F2'
})) 40001
$created = (Call-Api GET '/perf/indicators?keyword=TEST-W2-01' $hAdmin).Json.data.list[0]
Check 'disable indicator code' (Code (Call-Api POST "/perf/indicators/$($created.id)/status?status=0" $hAdmin $null)) 0
Check 'status after disable=0' (Call-Api GET "/perf/indicators/$($created.id)" $hAdmin).Json.data.status 0
Check 'delete indicator code' (Code (Call-Api DELETE "/perf/indicators/$($created.id)" $hAdmin $null)) 0
Check 'recreate same indicator code' (Code (Call-Api POST '/perf/indicators' $hAdmin $newInd)) 0

Write-Output ''
Write-Output '===== D. permission: employee blocked on cycle/indicator ====='
Check 'employee GET /perf/cycles code' (Code (Call-Api GET '/perf/cycles' $hEmp)) 40300
Check 'employee POST /perf/cycles code' (Code (Call-Api POST '/perf/cycles' $hEmp $newCycle)) 40300
Check 'employee GET /perf/indicators code' (Code (Call-Api GET '/perf/indicators' $hEmp)) 40300
Check 'employee POST /perf/indicators code' (Code (Call-Api POST '/perf/indicators' $hEmp $newInd)) 40300
Check 'hr GET /perf/cycles code' (Code (Call-Api GET '/perf/cycles' $hHr)) 0
Check 'hr GET /perf/indicators code' (Code (Call-Api GET '/perf/indicators' $hHr)) 0

Write-Output ''
Write-Output '===== E. regression: required fields / immutable code / dept CRUD / enums ====='

# --- cycle: missing required fields must be 40001, never DB 50000 ---
$reqCycle = @{
    cycleCode = 'TEST-NOEND'; cycleName = 'no end date'; cycleType = 'QUARTER'
    startDate = '2026-07-01'; endDate = '2026-09-30'
    selfDeadline = '2026-09-20 23:59:59'; managerDeadline = '2026-09-25 23:59:59'
    hrDeadline = '2026-09-28 23:59:59'; finalDeadline = '2026-09-30 23:59:59'
}
$bad = @{} + $reqCycle; $bad.Remove('endDate')
Check 'cycle missing endDate -> 40001' (Code (Call-Api POST '/perf/cycles' $hAdmin $bad)) 40001
$bad = @{} + $reqCycle; $bad.Remove('cycleType')
Check 'cycle missing cycleType -> 40001' (Code (Call-Api POST '/perf/cycles' $hAdmin $bad)) 40001
$bad = @{} + $reqCycle; $bad.Remove('finalDeadline')
Check 'cycle missing finalDeadline -> 40001' (Code (Call-Api POST '/perf/cycles' $hAdmin $bad)) 40001
$bad = @{} + $reqCycle; $bad.cycleType = 'WEEK'
Check 'cycle bad cycleType -> 40001' (Code (Call-Api POST '/perf/cycles' $hAdmin $bad)) 40001

# --- cycle: cycleCode is immutable after create ---
$keep = @{
    cycleCode = 'TEST-KEEP'; cycleName = 'immutable code test'; cycleType = 'QUARTER'
    startDate = '2026-07-01'; endDate = '2026-09-30'
    selfDeadline = '2026-09-20 23:59:59'; managerDeadline = '2026-09-25 23:59:59'
    hrDeadline = '2026-09-28 23:59:59'; finalDeadline = '2026-09-30 23:59:59'
}
$r = Call-Api POST '/perf/cycles' $hAdmin $keep
Check 'create TEST-KEEP code' (Code $r) 0
$keepId = $r.Json.data.id
$upd = @{ id = $keepId; cycleCode = '2026-Q1'; cycleName = 'renamed'; cycleType = 'QUARTER' }
Check 'update with changed code returns 0' (Code (Call-Api PUT "/perf/cycles/$keepId" $hAdmin $upd)) 0
Check 'cycleCode unchanged after update' (Call-Api GET "/perf/cycles/$keepId" $hAdmin).Json.data.cycleCode 'TEST-KEEP'
Check 'stale version -> 40901' (Code (Call-Api PUT "/perf/cycles/$keepId" $hAdmin @{id = $keepId; cycleName = 'lock'; cycleType = 'QUARTER'; version = 999})) 40901
Check 'delete TEST-KEEP code' (Code (Call-Api DELETE "/perf/cycles/$keepId" $hAdmin $null)) 0

# --- indicator: enum validation ---
Check 'indicator bad bizCategory -> 40001' (Code (Call-Api POST '/perf/indicators' $hAdmin @{
    indicatorCode = 'TEST-ENUM1'; indicatorName = 'bad category'; bizCategory = 'SALES'
    scoringType = 'QUANTITATIVE'; defaultFactorCode = 'F1'
})) 40001
Check 'indicator bad scoringType -> 40001' (Code (Call-Api POST '/perf/indicators' $hAdmin @{
    indicatorCode = 'TEST-ENUM2'; indicatorName = 'bad scoring type'; bizCategory = 'ABILITY'
    scoringType = 'TEXT'; defaultFactorCode = 'F1'
})) 40001
Check 'indicator bad enum on update -> 40001' (Code (Call-Api PUT '/perf/indicators/1' $hAdmin @{
    id = 1; bizCategory = 'BAD'
})) 40001

# --- dept CRUD (docs/03 defines POST/PUT/DELETE, now implemented) ---
$r = Call-Api GET '/system/depts' $hAdmin
Check 'dept list code' (Code $r) 0
Check 'dept list count=4' $r.Json.data.Count 4
$newDept = @{ parentId = 1; deptCode = 'DEPT_VERIFY'; deptName = 'verify dept'; sortNo = 99; status = 1 }
$r = Call-Api POST '/system/depts' $hAdmin $newDept
Check 'create dept code' (Code $r) 0
$vdId = $r.Json.data.id
Check 'new dept ancestors=0,1' $r.Json.data.ancestors '0,1'
Check 'duplicate dept code -> 40902' (Code (Call-Api POST '/system/depts' $hAdmin $newDept)) 40902
Check 'update dept code' (Code (Call-Api PUT "/system/depts/$vdId" $hAdmin @{
    id = $vdId; parentId = 1; deptCode = 'DEPT_VERIFY'; deptName = 'verify dept renamed'; sortNo = 98; status = 1
})) 0
Check 'dept renamed' (Call-Api GET "/system/depts/$vdId" $hAdmin).Json.data.deptName 'verify dept renamed'
Check 'delete dept with children -> 42201' (Code (Call-Api DELETE '/system/depts/1' $hAdmin $null)) 42201
Check 'delete dept with users -> 42201' (Code (Call-Api DELETE '/system/depts/2' $hAdmin $null)) 42201
Check 'delete empty dept code' (Code (Call-Api DELETE "/system/depts/$vdId" $hAdmin $null)) 0
Check 'recreate same dept code' (Code (Call-Api POST '/system/depts' $hAdmin $newDept)) 0
$vd2 = ((Call-Api GET '/system/depts' $hAdmin).Json.data | Where-Object { $_.deptCode -eq 'DEPT_VERIFY' } | Select-Object -First 1).id
Check 'cleanup verify dept' (Code (Call-Api DELETE "/system/depts/$vd2" $hAdmin $null)) 0

# --- role read (5 fixed roles per docs/03) ---
$r = Call-Api GET '/system/roles' $hAdmin
Check 'role list code' (Code $r) 0
Check 'role count=5' $r.Json.data.Count 5
Check 'role detail code' (Code (Call-Api GET '/system/roles/1' $hAdmin)) 0

# --- user DTO validation + permissions ---
Check 'user missing username -> 40001' (Code (Call-Api POST '/system/users' $hAdmin @{
    realName = 'no username'; deptId = 4; roleIds = @(1)
})) 40001
Check 'user missing roleIds -> 40001' (Code (Call-Api POST '/system/users' $hAdmin @{
    username = 'verify_u1'; realName = 'verify user'; deptId = 4; roleIds = @()
})) 40001
Check 'user duplicate username -> 40902' (Code (Call-Api POST '/system/users' $hAdmin @{
    username = 'admin'; realName = 'dup name'; deptId = 4; roleIds = @(1)
})) 40902
Check 'employee GET /system/users -> 40300' (Code (Call-Api GET '/system/users' $hEmp)) 40300
Check 'employee POST /system/depts -> 40300' (Code (Call-Api POST '/system/depts' $hEmp $newDept)) 40300

Write-Output ''
Write-Output ("===== SUMMARY PASS={0} FAIL={1} =====" -f $script:pass, $script:fail)