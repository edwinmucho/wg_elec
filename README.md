## <2018.04.26> Update
1. Gemfile 추가
 - Awesome Print
 - Rails db
2. DB 추가
 - sido : 광역시와 도 저장
 - gusigun : 일반시/군 그리고 구 저장
 - emd : 읍면동 저장
3. juso.rb 추가
 - 선거 정보 가져와서 DB에 저장하는 부분
4. CSV 파일 추가( juso.rb에 필요. )
 - emd.csv : 법정동 행정동 관련 csv 파일
 - sido.csv : 광역시 및 도를 찾기 쉽게 정리한 csv 파일


## <2018.05.01> Update
1. Mysql 적용
 - Gemfile : gem 'mysql2', '~> 0.3.18'
 - database.yml 수정
 - rake db:drop : 디비삭제
 - rake db:create : 데이터베이스 생성
 - rake db:migrate : 테이블 생성
 - error가 좀 많이 뜨면 mysql 서버 재시작! (mysql-ctl restart 복붙)
 - mysql shell 접속방법 (mysql-ctl cli 복붙)

2. findlist 중복 처리
 - juso.rb에서 bjsave() 수정.

3. 관할구역 변경에 대한 처리 부분 추가.
 - 읍면동 저장 부분에 추가됨.
 - 변경된 주소와 원래 주소를 둘다 db에 저장해서 찾기 수월하게 함.

4. 쿼리문 Mysql에 적용가능하게 변경.
 - 기존 : Sido.where("\"findlist\" LIKE \"%#{user_msg[0,2]}%\"")
 - 변경 : Sido.where("findlist LIKE ?", "%#{user_msg[0,2]}%")
 - 차이점  
   1. \" 할 필요 없음. 
   2. place holder ? 를 사용.


## <2018.05.09> Update

1. DB 저장 하는 부분을 웹으로 이동.
 - access code로 접근!
 - db 추가 / 삭제 가능하게 수정.


## <2018.05.18> Update

1. 카카오 컨트롤러 Refactoring
 - new_version_kakao_controller.rb (참고)
   - message 부분 정리 및 내용 분리
   - init_state 추가 : 각 키보드 및 메세지/유저 정보의의 초기화를 담당. (인자: text, user_key)
   - setAddress 추가 : 유저의 주소를 입력 받아 DB에 저장 하는 함수. (인자: user_msg)
   - next_func_step 추가 : 다음 기능 스텝을 관리 하는 함수. (인자: text, menu, fstep)
   - findCandidate 추가 : 선거 별로 후보 정보 불러오게 하는 함수. (인자: user_msg)
   - checkAddress 추가 : 유저의 현재 저장된 주소 정보 확인하는 함수. (인자: user_key)
   - check_user 추가 : 현재 유저에 대한 정보가 있는지 확인하고 없으면 만들어 주는 함수. (인자: user_key)
   - chat_room 함수 수정. (채팅방 정보 업데이트 부분 수정.)
   - friend_add 함수 수정. (유저 정보 초기화 추가)
 - User database 에 컬럼 추가.
   - 도/시/구/동 에 대한 명칭과 코드를 저장하는 부분 추가
   - chat_room 을 기존 string에서 integer로 변경.

2. 후보자를 웹에 표시하기 위한 내용 추가
 - HomepageController
 - view/homepage/*
 - Bootstrap 및 CSS 적용

## <2018.05.22> Update

1. User Database에 컬럼 추가
  - url : Json 정보를 가진 주소
2. 후보자를 웹에 뿌리기 위한 내용 추가
  - get 방식으로 유저 ID를 보내는 방식으로 controller 안에 묶인 데이터를 보내는걸로 대처함.
3. 정형화된 주소를 bitly api 를 이용하여 간략화 내용 추가. [BITLY 사이트](https://bitly.com/)
  - gem 'bitly' [GEM 참고 사이트](https://github.com/philnash/bitly) / [사용법 참고 사이트](https://richonrails.com/articles/shortening-urls-with-bit-ly)
  - urlshortener 함수 추가.
  - bitly 는 월 10000건의 주소변환이 무료. (중복 주소는 카운트 안됨. / 우리 주소는 유저명수와 동일. 즉 만명만 넘지 않으면 괜찮음.)


## <2018.05.26> Update

* Launching : Version 1.0

1. Json Url 오류 수정.
2. 사전 투표소 찾기 메뉴 추가
3. 후보자 페이지 수정.


## <2018.05.27> Update

1. delete hello controller(사용안하는 컨트롤러)
2. 사전 투표소 찾기 오류 수정.
3. 이전 step 부분 수정.


## <2018.05.28> Update

1. test 시 test가 db에 등록되는 부분 삭제.
2. 친구 차단시 db 및 user hash에서 삭제하는 부분 추가.
3. [버그 수정]
  - 후보자 찾기에 접속 > 10분 이상 해당 메뉴 방치 > 서버에서는 처음부터 시작 (but user step은 유지되고 있음.)
  - 각 step이 꼬여 에러가 무한정 발생.
  - message 에서 mstep 이 main 이 아니고 마지막 fstep이 초기 값이 아닌 경우. 오랜시간 방치로 판정하여 init 하는 부분 추가.
4. Bitly 대신 MessageButton으로 변경. 
5. 교육감 css 수정.
6. 일부 안내문구 수정.


## <2018.05.30> Update

* Update Version 1.1

1. 세종시 선거종류 수정.
2. 지역 뉴스 메뉴 추가.
3. 후보자 페이지에서 한자제거
4. 후보자 링크 수정.
5. 사전선거안내 메세지 타입 변경
6. 세종시, 제주도는 구,시,군의 장/의원 선거 제외.


## <2018.06.01> Update

* Update Version 1.2

1. 주소메뉴 관련 전면 개편 (도로명 주소 가능. feat.daum)
2. 읍면동 코드 저장 부분 수정.
3. 유저탈퇴시 db 삭제 => 카카오정보만 삭제.


## <2018.06.02> Update

* Update Version 1.3

1. 주소 가져오는 부분 수정.
2. 에러 발생시 예외처리 및 DB(버그리스트)에 내용 저장.


## <2018.06.04> Update

* Update Version 1.3.1

1. 주소 등록 부분 보완
2. 버그리스트에 컬럼추가 (Addlist 0604_01 add user_key)
3. 예외발생시 초기화 하는 부분 수정. (Buglist 0604_01 modified)
