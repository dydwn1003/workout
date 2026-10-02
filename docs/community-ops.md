# 커뮤니티 운영: 신고 처리 (24시간 안에)

앱스토어 심사 규칙(가이드라인 1.2)과 이용약관(web/terms.html)대로, 신고는 **24시간 안에** 확인해서 지우거나 작성자를 정지해야 합니다.

## 알림 받기 (한 번만 설정)

1. Supabase → Project Settings → **API Keys** → `secret`(또는 legacy `service_role`) 키 **복사**
2. GitHub 저장소 → Settings → Secrets and variables → Actions → **Secrets** → `SUPABASE_SERVICE_ROLE_KEY` 로 저장
   - 이 키는 모든 데이터를 읽고 쓸 수 있어요. 채팅이나 다른 곳에 붙여넣지 말고 여기에만 넣으세요.
3. 끝. `Community reports` 워크플로가 3시간마다 확인해서, 처리 안 된 신고가 있으면 **GitHub 이슈**("커뮤니티 신고 N건 확인 필요")를 열고 메일이 와요. 다 처리하면 이슈는 자동으로 닫혀요.
   - 바로 확인하려면 Actions → Community reports → Run workflow

## 신고 처리하기

Supabase → **SQL Editor** → New query 에서:

```sql
select * from report_queue;
```

신고된 글/댓글마다 신고 수, 사유, 내용(`body`), 작성자 닉네임, 자동으로 가려졌는지(`hidden`)가 보여요. 3명 이상 신고하면 이미 가려져 있어요.

각 줄의 `target_type`, `target_id` 로 한 줄씩 처리합니다.

| 하고 싶은 것 | SQL |
|---|---|
| 규칙 위반 → **지우고 작성자 정지** | `select community_resolve('post', '<target_id>', true, true);` |
| 지우기만 (가벼운 위반) | `select community_resolve('post', '<target_id>', true, false);` |
| 문제없음 → **다시 보이게** 두기 | `select community_resolve('post', '<target_id>', false, false);` |

댓글이면 `'post'` 대신 `'comment'`.

### 정지 풀기

```sql
select * from community_bans;                         -- 정지된 사람 목록
delete from community_bans where user_id = '<user_id>';  -- 정지 해제
```

정지된 사람은 글·댓글을 새로 쓰거나 고칠 수 없고, 앱에 "규칙 위반으로 글쓰기가 중단된 계정이에요"라고 나와요.

## 문의 메일

앱의 설정 → **문의하기**는 `dydwn1003@gmail.com` 으로 메일을 보냅니다 (다른 주소로 바꾸려면 빌드할 때 `--dart-define=SUPPORT_EMAIL=...`).
