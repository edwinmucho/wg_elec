require 'msgmaker'
require 'juso'
require 'rest-client'

class KakaoController < ApplicationController
  attr_reader :fin_url
  @@key = Msgmaker::Keyboard.new
  @@msg = Msgmaker::Message.new

  # 메뉴 종류
  MENU_STEP_FIND_CANDI    = "후보자 찾기"
  MENU_STEP_ADDRESS       = "내 주소 확인하기"
  MENU_STEP_ADD_ADDRESS   = "내 주소 등록/수정"
  MENU_STEP_FIND_PLACE = "사전투표소찾기"
  MENU_STEP_ADDRESS_NEWS = "우리지역 선거 뉴스"

  MENU_STEP_CHEERUP = "우리지역 정당 응원 현황"
  
  DEFAULT_MESSAGE = "메뉴를 골라 주세요."

  # 펑션 종류
  FUNC_STEP_INIT             = 0

  # 주소 저장 스텝
  FUNC_STEP_ADDRESS_INPUT    = 1
  FUNC_STEP_ADDRESS_CONFIRM  = 2
  FUNC_STEP_CHOICE_MENU      = 3
  FUNC_STEP_ADD_ADDRESS      = 4
  FUNC_STEP_CHECK_ADDRESS    = 5

  FUNC_STEP_STAY            = -1

  # 후보자 찾기 스텝
  FUNC_STEP_CHOICE_SGCODE    = 1

# 챗봇 메인 메뉴! 여기에 추가하면 메뉴가 추가됨.
  @@main_menu = [MENU_STEP_FIND_CANDI, MENU_STEP_ADDRESS,
                 MENU_STEP_FIND_PLACE, MENU_STEP_ADDRESS_NEWS]#, MENU_STEP_CHEERUP]
  # 설명 문장.
  DESC_FOR_ADDRESS_FIRST = "해당 메뉴는 선거구 주소를 확인 및 등록, 수정을 할수 있습니다.\n(선거구 주소는 언제든지\n등록/수정할 수 있습니다.)"

  # 클래스 변수와 전역 변수.
  @@user = {}
  
  def keyboard
    msg, keyboard_init = init_state("init_status")
    
    # ap "keyboard >>>>"
    # ap msg
    # ap keyboard_init
    
    render json: keyboard_init
  end

  def message
    
    user_msg = params[:content]
    user_key = params[:user_key]
    
    pic = false
    today = Time.now.getlocal('+09:00')

    # 기본 메세지와 키 값을 저장하는 부분.
    @next_msg, @next_keyboard = init_state("init_status")
# ap "Default msg/key >>>>>>>>>>"
# ap @next_msg
# ap @next_keyboard
# ap @next_keyboard[:buttons]
    
    
    # 유저별 세션 추가하는 부분. 없는 경우에만 동작. 
    check_user(user_key)
    
    if @next_keyboard[:buttons].include? user_msg and (@@user[user_key][:fstep][-1] > FUNC_STEP_INIT)
      init_state(user_key)
    end
ap "User stat >>>>"
ap user_key
ap @@user[user_key]

    # menu step 변경 하는 부분.
    if @@user[user_key][:mstep] == "main"
      @@user[user_key][:mstep] = user_msg if @next_keyboard[:buttons].include? user_msg
    end


    begin
      # 각 메뉴 진입.
      case @@user[user_key][:mstep]
      
        when MENU_STEP_ADDRESS
          @next_msg, @next_keyboard, ismsgBtn = func_Address(user_msg)
        when MENU_STEP_FIND_CANDI
          @next_msg, @next_keyboard, ismsgBtn = findCandidate(user_msg)
        when MENU_STEP_FIND_PLACE
          @next_msg, @next_keyboard, ismsgBtn = findPlace(user_key)
        when MENU_STEP_ADDRESS_NEWS
          @next_msg, @next_keyboard, ismsgBtn = election_new(user_key)
        when MENU_STEP_CHEERUP
          @next_msg, @next_keyboard, ismsgBtn = checkCheerup(user_key)  
        # when MENU_STEP_ADD_ADDRESS
        #   @next_msg, @next_keyboard = setAddress(user_msg)
        # when MENU_STEP_CHECK_ADDRESS
        #   @next_msg, @next_keyboard = checkAddress(user_key)
        else
          
      end
      
      # 에러 발생시 여기로 옴. #에러 로그를 여기서!
      rescue Exception => e
        err_msg = "#{e.message} ( #{e.backtrace.inspect.scan(/\/[a-zA-Z_]+\/[a-zA-Z_.:0-9]+in /)[0]} )"
        bug_list = Buglist.create(err_msg: err_msg, mstep: @@user[user_key][:mstep], fstep: @@user[user_key][:fstep], user_msg: user_msg, user_key: user_key)
        bug_list.save
        @next_msg, @next_keyboard = init_state("불편을 드려 죄송합니다.\n 다시 시도해 주세요.",user_key)
    end
    
    # ap " result >>>>>>"
    # ap @next_msg
    # ap @next_keyboard
    
    msg = @next_msg
    basic_keyboard = @next_keyboard

    if ismsgBtn
      # img_url = "http://mblogthumb3.phinf.naver.net/20131210_238/jjssoo1225_138665292681451K5y_GIF/%B1%CD%BF%A9%BF%EE%BE%C6%C0%CC%C4%DC%2C%BF%F2%C1%F7%C0%CC%B4%C2%C4%B3%B8%AF%C5%CD%2C%B1%CD%BF%A9%BF%EE%C4%B3%B8%AF%C5%CD%2C%BF%F2%C1%F7%C0%CC%B4%C2%C0%CC%B8%F0%C6%BC%C4%DC%2C%C0%CC%B9%CC%C1%F6%B8%F0%C0%BD%A8%E7_%284%29.gif?type=w2"
      # img_url = "/app/assets/images/logo_resize.jpg"
      result = {
        message: @@msg.getMessageBtn(@next_msg[0],@next_msg[1], @next_msg[2]),
        keyboard: basic_keyboard
      }
    else
      result = {
        message: @@msg.getMessage(msg.to_s),
        keyboard: basic_keyboard
      }
    end
    
    render json: result
  end

  def friend_add
    user_key = params[:user_key]
    if user_key != "test"
      res = User.where(user_key: user_key)[0]
  # ap "Check user >>>>>>>"      
  # ap user_key
  # ap res      
      if res.nil?
        User.create(user_key: user_key, chat_room: 0)
      end
      
      # User.create(user_key: params[:user_key], chat_room: 0)
     
      @@user[user_key] = 
      {
        :mstep => @mstep = "main",
        :fstep => @fstep = [FUNC_STEP_INIT]
      }
    end
    render nothing: true
  end

  def friend_del

    user_key = params[:user_key]
    user = User.where(user_key: user_key)[0]
    user.user_key = "서비스 탈퇴!"
    user.save
    
    @@user.delete(user_key)

    render nothing: true
  end

  def chat_room
    user = User.find_by(user_key: params[:user_key])
    if not user.nil?
      user.chat_room += 1
      user.save
    end
    render nothing: true
  end


  def check_user(user_key)
    if @@user[user_key].nil?
      @@user[user_key] = 
      {
        :mstep => @mstep = "main",
        :fstep => @fstep = [FUNC_STEP_INIT]
      }
      
      res = User.where(user_key: user_key)[0]
# ap "Check user >>>>>>>"      
# ap res      
      if res.nil?
        User.create(user_key: user_key, chat_room: "1")
      end
    end
  end


####################################################
  # private
  def init_state(text="", user_key)

    default_msg = (text == "") ? DEFAULT_MESSAGE : text + "\n\n" + DEFAULT_MESSAGE  # "메뉴를 골라 주세요."
    default_key = @@key.getBtnKey(@@main_menu)

    if user_key != "init_status"
      @@user[user_key] = 
      {
        :mstep => @mstep = "main",
        :fstep => @fstep = [FUNC_STEP_INIT]
      }
    end

    return default_msg, default_key
  end

####################################################

  def func_Address(user_msg)
    user_key = params[:user_key]
    user = User.find_by(user_key: user_key)
    
    # 주소 확인 할 수 있게 텍스트 만드는 부분.
    address = (user.sido.nil? or user.sido == "") ? 
    "등록된 주소가 없습니다." : "* 현재 선거구: #{user.sido} #{user.sigun} #{user.gu} #{user.emd}"
    address = address.gsub("  ", " ")    
    
    # 주소 메뉴
    @addr_main = [address, MENU_STEP_ADD_ADDRESS, "[ 처음으로 가기 ]"]
    # 주소 등록 문구 및 키보드 타입.
    @set_addr_menu = {
                "주소 또는 도로명 주소를 입력해 주세요.\n 예)서울 강남구 역삼1동\n 예)평창 군청길77\n['홈' 또는 '이전'을 치면 메뉴로 갈 수 있습니다.]" => @@key.getTextKey, # FUNC_STEP_INIT
                "주소 또는 도로명 주소를 입력해 주세요.\n 예)서울 중구 세종대로 110 (O)\n 예)부천시 상동\n['홈' 또는 '이전'을 치면 메뉴로 갈 수 있습니다.]" => @@key.getTextKey, # FUNC_STEP_ADDRESS_SIGUN
                "*가까운 주민센터*를 선택해주세요\n\n!목록에서 없다면 '이전'을 눌러\n주소를 더 자세히 적어주세요.\n" => "Button",
                "다시 시도해 주세요." => "STAY",
    }
    
    fstep = @@user[user_key][:fstep][-1]

# ap "fstep >>>>>>>>>>>"
# ap @@user[user_key][:fstep]
# ap fstep

    if user_msg == "이전"
        @@user[user_key][:fstep].pop # 현재 단계 저장된 STEP을 제거 이전단계만 남음.

        # 메뉴가 처음이어서 이전으로 돌아갈 상태가 없을때
        if @@user[user_key][:fstep][-1] == FUNC_STEP_CHOICE_MENU
          @temp_msg, @temp_key = nextstepwithmsg(DESC_FOR_ADDRESS_FIRST, @addr_main, FUNC_STEP_STAY)
        else
          @temp_msg, @temp_key = nextfuncwithmenu(@set_addr_menu, FUNC_STEP_STAY) # STAY는 현재 스텝 유지하고 스텝저장이 없음.
        end

    elsif user_msg == "홈" or user_msg == "[ 처음으로 가기 ]"
        @temp_msg, @temp_key = init_state(user_key)

    else # 홈과 이전이 아닌 user_msg 가 정보라고 판단하는 상태.

      # 처음 해당 Step으로 진입하여 첫 메뉴 준비.
      if fstep == FUNC_STEP_INIT
        @temp_msg, @temp_key = nextstepwithmsg(DESC_FOR_ADDRESS_FIRST, @addr_main, FUNC_STEP_CHOICE_MENU)
      # 주소 보기와 등록/수정을 처리하는 스텝
      elsif fstep == FUNC_STEP_CHOICE_MENU
        
        # 주소 등록 및 수정하는 스텝 처리.
        if user_msg == MENU_STEP_ADD_ADDRESS
          @temp_msg = @set_addr_menu.keys[0]
          @temp_key = @set_addr_menu[@temp_msg]
        
          @@user[user_key][:fstep].push(FUNC_STEP_ADDRESS_INPUT)
        
        # 주소를 누른 경우. 해당 메뉴 유지
        else
          @temp_msg, @temp_key = nextstepwithmsg(DESC_FOR_ADDRESS_FIRST, @addr_main, FUNC_STEP_STAY)
        end
        
      # 주소 등록 및 수정을 처리하는 스텝.        
      elsif fstep == FUNC_STEP_ADDRESS_INPUT
        
        juso = Juso::JsFind.new
        # user = User.find_by(user_key: user_key)    
        
        # 이곳에서 웹으로 주소를 받아오는 부분.
        full_addr = juso.search_addr(user_msg)
# ap "full_addr >>>>>"        
# ap full_addr

        # 검색된 주소가 있는지 확인!
        if full_addr.size == 0 or full_addr[:emd].nil?
          add_message = "#{user_msg} 은 찾을 수 없습니다.\n보다 정확히 입력해 주세요.\n " 
          @temp_msg, @temp_key = nextfuncwithmenu(add_message, @set_addr_menu, FUNC_STEP_STAY)
        else
          # 검색된 주소를 바탕으로 DB에서 정보 불러오기.
          sido_code = Sido.where("wiwname LIKE ? OR findlist LIKE ?", "%#{full_addr[:sido]}%", "%#{full_addr[:sido][0,2]}%").pluck(:wiwid)[0]
          sigun_code = Gusigun.where("townname LIKE ?","%#{full_addr[:sigun]}%").pluck(:towncode)[0] if not full_addr[:sigun].nil?
          gu_code = Gusigun.where("wiwid = ? AND townname LIKE ?", "#{sido_code}", "%#{full_addr[:gu]}%").pluck(:towncode)[0]
  
          
          # 광역시/도/시/군/구  저장.
          user.sido = full_addr[:sido]
          user.sigun = (full_addr[:sigun] != full_addr[:sido]) ? full_addr[:sigun] : nil
          user.gu = full_addr[:gu]
  
          user.sido_code = sido_code
          towncode = (full_addr[:gu].nil?)? sigun_code : gu_code
          user.gusigun_code = towncode

          # emd가 String 으로 전달되는 경우 (검색된 동이 1개인 경우)
          
          info_emd = Emd.where("towncode = ? AND (emdname LIKE ? or findlist LIKE ?)", "#{towncode}", "%#{full_addr[:emd]}%", "%#{full_addr[:emd]}%").pluck(:emdcode, :emdname)

          # info_emd가 한개인 경우 읍면동 저장.
          if info_emd.size == 1
            user.emd = info_emd[0][1]
            user.emd_code = info_emd[0][0]
            address = user.sido.to_s + " " + user.sigun.to_s + " " + user.gu.to_s + " " + user.emd.to_s
            address = address.gsub("  ", " ")   
            @temp_msg, @temp_key = init_state("#{address}\n 선거구 저장완료.\n(주소지와 동이 다른 경우는\n 선거구로 묶인 동으로 자동 선택된 것입니다.)",user_key)
            # user db 저장.
            user.save
          # info_emd 가 여러개인 경우 해당 동이 행정동에 묶여 있는 경우임.
          elsif info_emd.size != 0
            btn = []
            info_emd.each{|v| btn.push(v[1])}
            @temp_msg, @temp_key = button_confirm(@set_addr_menu,btn,FUNC_STEP_ADDRESS_CONFIRM)  
            # user db 저장.
            user.save
          else
            add_message = "#{user_msg} 은 찾을 수 없습니다.\n보다 정확히 입력해 주세요.\n " 
            @temp_msg, @temp_key = nextfuncwithmenu(add_message, @set_addr_menu, FUNC_STEP_STAY)
          end
          
        end
      
      # 동이 여러개인 경우 처리하는 부분.
      elsif fstep == FUNC_STEP_ADDRESS_CONFIRM
        user = User.find_by(user_key: user_key)

        res = Emd.where("emdname = ? AND towncode = ?", user_msg, user.gusigun_code)[0] #Bug_list 0531_01

        user.emd_code = res.emdcode
        user.emd = res.emdname
        user.save
        address = user.sido.to_s + " " + user.sigun.to_s + " " + user.gu.to_s + " " + user.emd.to_s
        address = address.gsub("  ", " ")   
        @temp_msg, @temp_key = init_state("#{address}\n 선거구 저장완료.\n(주소지와 동이 다른 경우는\n 선거구로 묶인 동으로 자동 선택된 것입니다.)",user_key)
      
      # 잘못된 접근을 하는 경우.      
      else 
        @temp_msg, @temp_key = init_state(user_key)
      end
    end

    return @temp_msg, @temp_key, false
  end

####################################################
  
  def nextfuncwithmenu(text="", menu, fstep)
# ap "nextfuncwithmenu >>>>>"    
# ap text
# ap fstep
# ap menu.keys[fstep]
# ap menu.class
    user_key = params[:user_key] 
    # STAY 인 경우 현재 스텝 유지.
    indx = (fstep == FUNC_STEP_STAY) ? @@user[user_key][:fstep][-1] : fstep
    
    # 추가 문구가 있는 경우.  
    if menu.class == Hash
      @msg = (text == "") ? menu.keys[indx] : text.to_s + "\n" + menu.keys[indx].to_s
      @keytype = menu[@msg]
    else
      @msg = text
      @keytype = @@key.getTextKey
    end
    
    if fstep != FUNC_STEP_STAY
      @@user[user_key][:fstep].push(fstep)
    end
    
    return @msg, @keytype

  end
####################################################

  def nextstepwithmsg(msg, btn, fstep)
    user_key = params[:user_key]
    
    if btn != "" and not btn.nil? and (btn.class == Array)
      @keytype = @@key.getBtnKey(btn)
    else
      @keytype = @@key.getTextKey
    end
  
    if fstep != FUNC_STEP_STAY
      @@user[user_key][:fstep].push(fstep)
    end
  
    return msg, @keytype
  end

####################################################

  def nextstepwithmsg(msg, btn, fstep)
    user_key = params[:user_key]
    
    if btn != "" and not btn.nil? and (btn.class == Array)
      @keytype = @@key.getBtnKey(btn)
    else
      @keytype = @@key.getTextKey
    end
  
    if fstep != FUNC_STEP_STAY
      @@user[user_key][:fstep].push(fstep)
    end
  
    return msg, @keytype
  end

####################################################

  def findCandidate(user_msg)
    user_key = params[:user_key]
    @sun_code = {
                 "시,도지사선거 후보"=> "3",
                 "구,시,군의 장선거 후보"=> "4",
                 "시,도의회의원선거 후보"=> "5",
                 "구,시,군의회의원선거 후보"=> "6",
                 "교육감선거 후보"=> "11",
                 "[ 처음으로 가기 ]"=> "90"
                }
    ismsgBtn = false
    
    fstep = @@user[user_key][:fstep][-1]

    if user_msg == "[ 처음으로 가기 ]"
      @temp_msg, @temp_key = init_state(user_key)
    else
      user = User.where(user_key: user_key)[0]
      
      # 세종시 및 제주인 경우 해당 선거가 존재하지 않음. 메뉴에서 제거.
      if ["4900", "5100"].include?(user.sido_code)
        @sun_code.delete("구,시,군의 장선거 후보")
        @sun_code.delete("구,시,군의회의원선거 후보")
      end

      if fstep == FUNC_STEP_INIT
        
        if (user.sido.nil? or user.sido_code.nil? or 
            user.emd.nil? or user.emd_code.nil?) or 
            !corr_address(user)
     
          text = (user.sido.nil? or user.sido == "") ? "[내 주소 확인하기] 메뉴에서\n 주소를 등록해 주세요." : "#{user.sido} #{user.gu} #{user.sigun} #{user.emd}\n등록된 주소를 확인해 주세요."
          @temp_msg, @temp_key = init_state(text,user_key)
        else
          @temp_msg, @temp_key = nextstepwithmsg("어떤 후보자를 찾고 있습니까?",@sun_code.keys, FUNC_STEP_CHOICE_SGCODE)
        end
        
      elsif fstep == FUNC_STEP_CHOICE_SGCODE
        sgcode = @sun_code[user_msg]

        if user.sido_code.nil? or user.gusigun_code.nil? or user.emd_code.nil?
          @temp_msg, @temp_key = init_state("주소를 다시 한번 확인해 주세요.",user_key)
        else

          sggurl = "http://info.nec.go.kr/main/main_election_jd_sgg.json?electionId=0020180613&sgTypeCode=#{sgcode}&emdCode=#{user.emd_code}"
     
          sggresponse = RestClient.get(sggurl)
          sggparsed = JSON.parse(sggresponse)
          # ap "-------------"
          # ap sggurl
          # ap sggparsed
          # ap sggparsed["SggMap"][0]["CODE"]
       
          sggcode = sggparsed["SggMap"][0]["CODE"]
          
          url = "http://info.nec.go.kr/main/main_election_candidate.json?electionId=0020180613&sgTypeCode=#{sgcode}&sggCode=#{sggcode}&emdCode=#{user.emd_code}&startIndex=0&endIndex=25"
          
          user = User.where(user_key: user_key)[0]
          user.url = url
          user.save
          
          root = ENV["ROOT_URL"]
          
          m_url = "#{root}/homepage/result/#{user.id}"
          label = user_msg
          text = "후보자 명단 입니다."
          
          temp = Array.new
          temp.push(text)
          temp.push(label)
          temp.push(m_url)
          
          @temp_msg = temp
          ismsgBtn = true
          
          @temp_key = @@key.getBtnKey(@sun_code.keys)  
        end
      end
    end
    
    return @temp_msg, @temp_key, ismsgBtn
  end
####################################################
## 투표소 

  def findPlace(user_key)
    
    ismsgBtn = false
    user_key = params[:user_key]
    user = User.find_by(user_key: user_key)
    
    if user.emd_code.nil? or user.emd_code.length < 4
      @temp_msg, @temp_key = init_state("등록된 주소가 없습니다.",user_key)
    else
      emdcode = user.emd_code
      # ap emdcode
      
      # url = "http://info.nec.go.kr/main/main_load_sub.xhtml?tabMenuId=PrePoll&electionId=0020180613&emdCode=#{emdcode}&pgmPath=/main/main_prevote.jsp"
      placeurl = "http://info.nec.go.kr/m/main/main_load_sub.xhtml?electionId=0020180613&pgmPath=/main/main_prevote.jsp&tabMenuId=PrePoll&emdCode=#{emdcode}&"
      
      placedata = RestClient.get(placeurl)
      placejson = JSON.parse(placedata)
      pollplace = placejson["jsonResult"]["body"]["model"]["tupyosoList"][0]["TPSJUSO"]
# ap pollplace.gsub(" ", "")
      
      placemap = "https://map.naver.com/?query="+pollplace.gsub(" ", "")

      text = "사전투표안내\n일시: 6월8일(금)~9일(토)\n시간: 오전6시~오후6시\n\n장소는 아래 링크를 눌러주세요."
      label = "#{user.emd} 사전 투표장은 이곳!"
      # url = urlshortener(placemap)
 
      @temp_msg, @temp_key = init_state(user_key)
      temp = Array.new
      temp.push(text)
      temp.push(label)
      temp.push(placemap)
      
      @temp_msg = temp
      ismsgBtn = true
    end
  
    return @temp_msg, @temp_key, ismsgBtn  
  end
  
####################################################
  def checkAddress(user_key)
    user = User.where(user_key: user_key)[0]
# ap "check addr >>>"    
# ap user_key
    @temp_msg, @temp_key = init_state(user_key)
    
    if user.sido.nil?
      @temp_msg = "저장된 주소가 없습니다.\n" + @temp_msg
    else
      @temp_msg = "주소: #{user.sido} #{user.sigun} #{user.gu} #{user.emd} \n" + @temp_msg
    end
  
    return @temp_msg, @temp_key  
  end
##################################################
  def urlshortener(url)
    require "bitly"
    
    bitly = Bitly::V3::Client.new(ENV["BITLY_ID"], ENV["BITLY_API_KEY"])
    
    res = bitly.shorten(url)
    
    return res.short_url
  end
##################################################
  def corr_address(user)

# ap "correct address >>>>>>>"
# ap user
# ap user.sido_code[0,2]
# ap user.gusigun_code[0,4]
# ap user.emd_code[0,4]

    return  ((user.sido_code[0,2] == user.gusigun_code[0,2]) and 
            (user.gusigun_code[0,4] == user.emd_code[0,4])) ?  true : false
  end

###################################################
  def checkCheerup(user_key)
    user = User.where(user_key: user_key)[0]  
    total = Jdcheer.where(gsg_code: user.gusigun_code).sum(:cheerup)
    ismsgBtn = false
    
    if not (total == 0 or user.nil?)
      name = (user.gu.nil? or user.gu == "") ? user.sigun : user.gu
      text = " - #{name} 정당별 응원 지수 -\n"
      count_list = Jdcheer.where(gsg_code: user.gusigun_code).pluck(:jdname, :cheerup).sort_by{|jdname, cheerup| -cheerup}
      count_list.each do |jdname, cheerup|
        text += "#{jdname} : #{(cheerup * 100.0 / total).round(1)}% (#{cheerup}홧팅!)\n"
      end
      ismsgBtn = true
      temp = []
      label = "정당 별 응원 현황"
      root = ENV["ROOT_URL"]
      m_url = "#{root}/homepage/cheerup_result"
      # m_url = "http://52.15.121.230/homepage/cheerup_result" # for deploy
ap text
ap label
ap m_url      
      temp.push(text)
      temp.push(label)
      temp.push(m_url)
      @temp_msg, @temp_key = init_state(user_key)
      @temp_msg = temp
    else
      @temp_msg, @temp_key = init_state("아직 응원전이네요!\n 후보목록에서 지지 정당을 응원해 봐요!\n",user_key)
    end
    
    return @temp_msg, @temp_key, ismsgBtn
  end

###################################################
  def election_new(user_key)
    news_code = {
      "서울" => "667363", "부산" => "667388", "대구" => "667405", "인천" => "667414",
      "광주" => "667425", "대전" => "667431", "울산" => "667437", "세종" => "667443",
      "경기" => "667444", "강원" => "667476", "충북" => "667495", "충남" => "667507",
      "전북" => "667523", "전남" => "667538", "경북" => "667561", "경남" => "667585",
      "제주" => "667604"
    }
    
    sido = User.where(user_key: user_key).pluck(:sido)[0]
    
    code = (sido.length == 4) ? "#{sido[0]}#{sido[2]}" : "#{sido[0,2]}"

    @temp_msg, @temp_key = init_state(user_key)
    news_url = "http://election.daum.net/20180613/news/district/#{news_code[code]}"
    temp = []
    text = "#{sido} 지역 뉴스"
    label = "#{sido} 지역 뉴스"
    
    temp.push(text)
    temp.push(label)
    temp.push(news_url)
    
    @temp_msg = temp  
    return @temp_msg, @temp_key, isMsgBtn=true

  end
##################################################
 def button_confirm(menu, btn_list, nstep)
  btn = Array.new
  btn = btn_list
  btn.push("이전")
  @temp_msg, @temp_key = nextfuncwithmenu(menu, nstep)
  @temp_key = @@key.getBtnKey(btn)
  
  return @temp_msg, @temp_key
 end
  
end
