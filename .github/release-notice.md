## 내려받기

| 대상 | 받는 법 |
| --- | --- |
| **Linux 64비트** | `filetagger-…-linux-x64.tar.gz` — 압축을 풀고 그 안의 실행 파일을 바로 실행하는 포터블판입니다 (Ubuntu 22.04 이상에 준하는 glibc · GTK3 필요) |
| **Windows** | 산출물을 싣지 않습니다 — 서명 없는 실행 파일은 내려받으면 SmartScreen 경고를 만나기 때문입니다. 저장소 `README.md`의 빌드 안내를 따르면 같은 포터블판이 만들어집니다 |
| **Microsoft Store** | 준비 중입니다 |

포터블판은 **설정을 실행 파일과 같은 폴더에 저장합니다.** 레지스트리나 시스템 폴더에는
아무것도 남기지 않으므로 폴더째 옮기거나 지우면 그것으로 끝입니다.

내려받은 파일은 `SHA256SUMS.txt`로 검증할 수 있습니다.

```bash
sha256sum --check --ignore-missing SHA256SUMS.txt
```

---
