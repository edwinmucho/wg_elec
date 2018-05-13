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