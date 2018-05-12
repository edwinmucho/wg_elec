require 'msgmaker'
require 'juso'

class KakaoController < ApplicationController
  @@key = Msgmaker::Keyboard.new
  @@msg = Msgmaker::Message.new

  # 메뉴 종류
  MENU_STEP_HOME       = "HOME"
  MENU_STEP_FIND_CANDI = "후보자 찾기"
  MENU_STEP_SECOND     = "다른 메뉴 넣을거."


  MENU_STEP_2JANG      = "아아 이장입니다." # 비밀 메뉴. DB 업뎃용. 메인메뉴에 잠깐 추가시키면됨.

  # 펑션 종류
  FUNC_STEP_TYPE_OF_ELECTION = 10
  FUNC_STEP_CHOICE_SIDO      = 11
  FUNC_STEP_CHOICE_SIGUN     = 12
  FUNC_STEP_CHOICE_GU        = 13
  FUNC_STEP_CHOICE_EMD       = 14
  FUNC_STEP_ONEMORE_CONFIRM  = 15

  # 이동 종류
  FUNC_STEP_INIT       = 0
  FUNC_STEP_FINISH     = 99

  LETS_GO_HOME         = 90

  # 클래스 변수와 전역 변수.
  @@main_menu = [MENU_STEP_HOME,MENU_STEP_FIND_CANDI,MENU_STEP_SECOND,MENU_STEP_2JANG]

  @@rem = Array.new
  @@mstep = MENU_STEP_HOME
  @@fstep = 0

  $_sgcode = ""
  $_wiwid = ""
  $_towncode = ""
  $_emdcode = ""

  $sido = ""
  $gusigun = ""
  $emd = ""



  def keyboard
    render json: @@key.getBtnKey(@@main_menu)
  end

  def message
    # 선거 종류
    @sun_code = {
                 "시,도지사선거"=> "3",
                 "구,시,군의 장선거"=> "4",
                 "시,도의회의원선거"=> "5",
                 "구,시,군의회의원선거"=> "6",
                 "교육감선거"=> "11",
                 "홈"=> "90"
                }
    # 주소 선택 메뉴 및 키보드 타입
    @juso_menu = {
                  "선거 종류를 선택하세요.[홈/이전/다시]" => @@key.getBtnKey(@sun_code.keys), #FUNC_STEP_TYPE_OF_ELECTION
                  "광역시 혹은 도를 입력하세요.[홈/이전/다시]" => @@key.getTextKey,           #FUNC_STEP_CHOICE_SIDO
                  "시 또는 군을 선택하세요. [홈/이전/다시]" => @@key.getTextKey,              #FUNC_STEP_CHOICE_SIGUN
                  "구 를 선택하세요.[홈/이전/다시]" => @@key.getTextKey,                      #FUNC_STEP_CHOIVE_GU
                  "동을 입력하세요.[홈/이전/다시]" => @@key.getTextKey,                       #FUNC_STEP_CHOICE_EMD
                  "다음중 어떤것인가요?.[홈/이전/다시]" => @@key.getBtnKey(@@main_menu)       #FUNC_STEP_ONEMORE_CONFIRM
    }

    user_key = params[:user_key]

    ap "session >>>>>>"
    ap session.empty?
    ap session[user_key]
    
    user_msg = params[:content]
    basic_keyboard = @@key.getBtnKey(@@main_menu)

    pic = false
    today = Time.now.getlocal('+09:00')

    case @@mstep

      when MENU_STEP_FIND_CANDI
        keyflag = false
        # 카톡에서 오는 부분을 체크함.
        # 정보 일수도 있고 메뉴 선택일 수도 있기 때문에 일단 관리함.
        if user_msg == "이전"
          a = @@rem.pop                # 한번 더 빼야 이전 단계를 찾음.
          @@fstep = @@rem.size > 0 ? @@rem.pop : FUNC_STEP_TYPE_OF_ELECTION
          keyflag = true
          msg = @juso_menu.keys[@@fstep - 10]
          basic_keyboard = @juso_menu[msg]

        elsif user_msg == "다시"
          @@fstep = FUNC_STEP_TYPE_OF_ELECTION
          keyflag = true
          msg = @juso_menu.keys[@@fstep - 10]
          basic_keyboard = @juso_menu[msg]

        elsif user_msg == "홈"
          @@mstep = MENU_STEP_HOME
          @@fstep = FUNC_STEP_INIT
          @@rem.clear
          msg = "어떤것을 원하시나요?"
          basic_keyboard = @@key.getBtnKey(@@main_menu)
        else
          # 유저 입력 받은 값.

        end

        # 유저한테 받은 카톡 메세지가 데이터인 경우 처리하는 부분
        if !keyflag and @@fstep == FUNC_STEP_TYPE_OF_ELECTION
          $_sgcode = @sun_code[user_msg]  # 선거 코드 물어본거 여기 저장.
          @@fstep = FUNC_STEP_CHOICE_SIDO # 다음 단계로 이동.

          msg = @juso_menu.keys[@@fstep - 10]
          basic_keyboard = @juso_menu[msg]
          @@rem.push(@@fstep)

        elsif !keyflag and @@fstep == FUNC_STEP_CHOICE_SIDO

          res = Sido.where("wiwname LIKE ?", "%#{user_msg[0,2]}%")#.pluck(:wiwid)

          if res.length == 0
            # q2 = "\"findlist\" LIKE \"%#{user_msg[0,2]}%\""
            res = Sido.where("findlist LIKE ?","%#{user_msg[0,2]}%")#.pluck(:wiwid)
          end

          if res.length == 0
            @@fstep = FUNC_STEP_CHOICE_SIDO
          else
            fin = Sido.find_by("wiwid": res[0].wiwid)                # 어떤 광역시 인지 도인지 확인.
            $sido = fin.gusigun                                # 해당 지역이 여기에 저장. (광역시라면 : 구 / 도라면 : 시군)
            $_wiwid = fin.wiwid                                # 시도 코드 입력 부분.

            if fin.gusigun[0].wiwtypecode == "29"              # 29 : 광역시인 부분. (시/군 패스 어느 구인지 묻는 대화)
              @@fstep = FUNC_STEP_CHOICE_GU
            else                                               # 시/군 정보 받는걸로.
              @@fstep = FUNC_STEP_CHOICE_SIGUN
            end
            @@rem.push(@@fstep)                                # 메뉴 상태 저장.
          end

          msg = @juso_menu.keys[@@fstep - 10]
          basic_keyboard = @juso_menu[msg]


        elsif !keyflag and @@fstep == FUNC_STEP_CHOICE_SIGUN
          # q1 = "\"townname\" LIKE \"%#{user_msg[0,2]}%\""
          # res = $sido.find_by(q1)
          res = $sido.find_by("townname LIKE ?", "%#{user_msg[0,2]}%")

          if res.nil?
            @@fstep = FUNC_STEP_CHOICE_SIGUN
          else
            $gusigun = res
            if $gusigun.wiwtypecode == "30"                  # 구가 있는 시인 경우.
              @@fstep = FUNC_STEP_CHOICE_GU
            else
              @@fstep = FUNC_STEP_CHOICE_EMD                 # 구가 없는 시/군인 경우
              $_towncode = $gusigun.towncode
            end
            @@rem.push(@@fstep)                                # 메뉴 상태 저장.
          end
          msg = @juso_menu.keys[@@fstep - 10]
          basic_keyboard = @juso_menu[msg]

        elsif !keyflag and @@fstep == FUNC_STEP_CHOICE_GU

          # q1 = "\"townname\" LIKE \"%#{user_msg[0,2]}%\""
          # res = $sido.find_by(q1)

          res = $sido.find_by("townname LIKE ?", "%#{user_msg[0,2]}%")

          if res.nil?
            @@fstep = FUNC_STEP_CHOICE_GU
          else
            $gusigun = res
            $_towncode = res.towncode
            @@fstep = FUNC_STEP_CHOICE_EMD
            @@rem.push(@@fstep)                                # 메뉴 상태 저장.
          end
          msg = @juso_menu.keys[@@fstep - 10]
          basic_keyboard = @juso_menu[msg]

        elsif !keyflag and @@fstep == FUNC_STEP_CHOICE_EMD

          um = user_msg.gsub(/\s/, "")

          # q1 = "\"emdname\" LIKE \"%#{um}%\""
          # res = $gusigun.emd.where(q1).pluck(:emdcode, :emdname)
          res = $gusigun.emd.where("emdname LIKE ?","%#{um}%").pluck(:emdcode, :emdname)
          if res.size == 0
            # q2 = "\"findlist\" LIKE \"%#{um}%\""
            # res = $gusigun.emd.where(q1).pluck(:emdcode, :emdname)
            res = $gusigun.emd.where("findlist LIKE ?","%#{um}%").pluck(:emdcode, :emdname)
          end

          if res.size == 0                                # 한번 더
            @@fstep = FUNC_STEP_CHOICE_EMD
            msg = @juso_menu.keys[@@fstep - 10]
            basic_keyboard = @juso_menu[msg]
          elsif res.size > 1                              # 버튼 선택
            $emd = res
            btn = Array.new
            res.each {|v| btn.push(v[1])}
            @@fstep = FUNC_STEP_ONEMORE_CONFIRM
            msg = @juso_menu.keys[@@fstep - 10]
            basic_keyboard = @@key.getBtnKey(btn)
          else
            $emd = res
            $_emdcode = res[0][0]
            @@fstep = FUNC_STEP_FINISH
          end
        elsif @@fstep == FUNC_STEP_ONEMORE_CONFIRM
          tc = ""

          $emd.each {|v| tc = v[0] if v[1] == user_msg}
          $_emdcode = tc
          @@fstep = FUNC_STEP_FINISH
        else
          # 아무것도 하지 않음.
        end


        if @@fstep == FUNC_STEP_FINISH

ap "##### Last Status #####"
ap "sgcode   : #{$_sgcode}"
ap "wiwid    : #{$_wiwid}"
ap "towncode : #{$_towncode}"
ap "emdcode  : #{$_emdcode}"
ap "#######################"


          tail_num = ["3","4","11"].include?($_sgcode) ? "00" : "01"
          midle_num = ["3","11"].include?($_sgcode) ? "#{$_wiwid}" : "#{$_towncode}"

          fin_url = "http://info.nec.go.kr/main/main_election_precandidate.json?electionId=0020180613&sgTypeCode=#{$_sgcode}&sggCode=#{$_sgcode}#{midle_num}#{tail_num}&emdCode=#{$_emdcode}&startIndex=0&endIndex=9"
          msg = " #{fin_url} 입니다. "
          basic_keyboard = @@key.getBtnKey(@@main_menu)
          @@fstep = FUNC_STEP_INIT
          @@mstep = MENU_STEP_HOME
        end
        # 데이터가 제대로 리턴되었을때 다음 단계 진행.
        # 데이터가 제대로 리턴되지 않으면 현재 단계 다시 진행. Log 남기게 추가.
# ap "##### Check Status #####"
# ap @@fstep
# ap msg
# ap basic_keyboard
# ap "########################"

      else

        # 메뉴 변경은 이곳에서
        meslist = ["어떤것을 원하시나요?", "선거종류를 선택해 주세요.", "필요한거 있나요?"]

        @@mstep = user_msg
        @@fstep = 0

        # 후보자 찾기 부분.
        if @@mstep == MENU_STEP_FIND_CANDI
          msg = meslist[1]
          basic_keyboard = @@key.getBtnKey(@sun_code.keys)

          @@fstep = FUNC_STEP_TYPE_OF_ELECTION
          @@rem.push(FUNC_STEP_TYPE_OF_ELECTION)
        elsif @@mstep == "아아 이장입니다."
          msg = "디비 저장 모드입니다. 뭘 저장 할까요?"
          basic_keyboard = @@key.getTextKey
        else
          msg = "어떤것을 원하시나요?"
          basic_keyboard = @@key.getBtnKey(@@main_menu)
        end

        # f = Juso::JsFind.new
        # as=user_msg
        # fl = [f.a(as), f.b(as), f.c(as)]

        # um = user_msg
        # msg = fl[um.to_i]

        # basic_keyboard = @@key.getTextKey
    end

    session[user_key] = "AAAAAA"

    result = {
      message: @@msg.getMessage(msg.to_s),
      keyboard: basic_keyboard
    }
# ap "#######"
# ap result
# ap "#######"
    render json: result
  end
  def friend_add
    user_key = params[:user_key]
    #새로운 유저를 저장해주세요
    render nothing: true
  end

  def friend_add
    User.create(user_key: params[:user_key], chat_room: 0)
    render nothing: true
  end

  def chat_room
    user = User.find_by(user_key: params[:user_key])
    user.plus
    user.save
    render nothing: true
  end

end
