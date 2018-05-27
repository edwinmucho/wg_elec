require 'msgmaker'
require 'juso'
require 'rest-client'

class KakaoController < ApplicationController
  attr_reader :fin_url
  @@key = Msgmaker::Keyboard.new
  @@msg = Msgmaker::Message.new

  # 메뉴 종류
  MENU_STEP_FIND_CANDI    = "후보자 찾기"
  MENU_STEP_ADD_ADDRESS   = "내 주소등록/수정"
  MENU_STEP_CHECK_ADDRESS = "내 주소 확인"
  MENU_STEP_FIND_PLACE = "사전투표소찾기"
  
  DEFAULT_MESSAGE = "메뉴를 골라 주세요."

  # 펑션 종류
  FUNC_STEP_INIT             = 0

  # 주소 저장 스텝
  FUNC_STEP_ADDRESS_SIGUN    = 1
  FUNC_STEP_ADDRESS_GU       = 2
  FUNC_STEP_ADDRESS_EMD      = 3
  FUNC_STEP_ADDRESS_CONFIRM  = 4
  
  FUNC_STEP_RETRY            = -1

  # 후보자 찾기 스텝
  FUNC_STEP_CHOICE_SGCODE    = 1




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



    # 각 메뉴 진입.
    case @@user[user_key][:mstep]
    
      when MENU_STEP_ADD_ADDRESS
        @next_msg, @next_keyboard = setAddress(user_msg)
      when MENU_STEP_FIND_CANDI
        @next_msg, @next_keyboard, @ismsgBtn = findCandidate(user_msg)
      when MENU_STEP_CHECK_ADDRESS
        @next_msg, @next_keyboard = checkAddress(user_key)
      when MENU_STEP_FIND_PLACE
        @next_msg, @next_keyboard = findPlace(user_key)
      else
        
      end


    # ap " result >>>>>>"
    # ap @next_msg
    # ap @next_keyboard
    
    msg = @next_msg
    basic_keyboard = @next_keyboard

    if @ismsgBtn
      # img_url = "http://mblogthumb3.phinf.naver.net/20131210_238/jjssoo1225_138665292681451K5y_GIF/%B1%CD%BF%A9%BF%EE%BE%C6%C0%CC%C4%DC%2C%BF%F2%C1%F7%C0%CC%B4%C2%C4%B3%B8%AF%C5%CD%2C%B1%CD%BF%A9%BF%EE%C4%B3%B8%AF%C5%CD%2C%BF%F2%C1%F7%C0%CC%B4%C2%C0%CC%B8%F0%C6%BC%C4%DC%2C%C0%CC%B9%CC%C1%F6%B8%F0%C0%BD%A8%E7_%284%29.gif?type=w2"
      # img_url = "/app/assets/images/logo_resize.jpg"
      result = {
        message: @@msg.getMessageBtn("후보자 명단 입니다.",@temp_msg[0], @temp_msg[1]),
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
    user.destroy
    
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
    main_menu = [MENU_STEP_FIND_CANDI,MENU_STEP_ADD_ADDRESS, MENU_STEP_CHECK_ADDRESS, MENU_STEP_FIND_PLACE]
    
    default_msg = text == "" ? DEFAULT_MESSAGE : text + "\n\n" + DEFAULT_MESSAGE  # "메뉴를 골라 주세요."
    default_key = @@key.getBtnKey(main_menu)
# ap ">>>>>>>>"    
# ap user_key
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

  def setAddress(user_msg)
    user_key = params[:user_key]
    @addr_menu = {
                "주소지에 해당하는 시 또는 군을 입력하세요.\n 예) 서울시, 의성군...\n [홈 또는 이전 을 치면 해당 메뉴로 갈 수 있습니다.]" => @@key.getTextKey, # FUNC_STEP_INIT
                "주소지에 해당하는 시 또는 군을 입력하세요.\n 예) 전주시, 단양군, 춘천...\n[홈 또는 이전 을 치면 해당 메뉴로 갈 수 있습니다.]" => @@key.getTextKey, # FUNC_STEP_ADDRESS_SIGUN
                "구를 입력하세요.\n [홈 또는 이전 을 치면 해당 메뉴로 갈 수 있습니다.]" => @@key.getTextKey,                                                   # FUNC_STEP_ADDRESS_GU
                "읍면동을 입력하세요.\n [홈 또는 이전 을 치면 해당 메뉴로 갈 수 있습니다.]" => @@key.getTextKey,                                               # FUNC_STEP_ADDRESS_EMD
                "버튼에서 골라주세요." => "Button",
                "다시 시도해 주세요." => "RETRY",
    }
    
    fstep = @@user[user_key][:fstep][-1]
#   FUNC_STEP_INIT             = 0    
#   FUNC_STEP_ADDRESS_SIGUN    = 1
#   FUNC_STEP_ADDRESS_GU       = 2
#   FUNC_STEP_ADDRESS_EMD      = 3
#   FUNC_STEP_ADDRESS_CONFIRM  = 4

# ap "fstep >>>>>>>>>>>"
# ap @@user[user_key][:fstep]
# ap fstep

    if user_msg == "이전"
        @@user[user_key][:fstep].pop # 현재 단계 저장된 STEP을 제거
# ap "before >>>>>>>>>>"
# ap @@user[user_key][:fstep]
# ap fstep
        @temp_msg, @temp_key = nextfuncstep(@addr_menu, FUNC_STEP_RETRY)
    elsif user_msg == "홈"
        @temp_msg, @temp_key = init_state(user_key)
    else
      if fstep == FUNC_STEP_INIT
        @temp_msg = @addr_menu.keys[fstep]
        @temp_key = @addr_menu[@temp_msg]
        
        
        @@user[user_key][:fstep].push(FUNC_STEP_ADDRESS_SIGUN)
        
      elsif fstep == FUNC_STEP_ADDRESS_SIGUN
        
        res = Sido.where("wiwname LIKE ?", "%#{user_msg[0,2]}%")[0]
# ap "지역 추가 >>>>>>"
# ap res.wiwid.to_i > 3100 if not res.nil?
        if res.nil?  or res.wiwid == "5100" or res.wiwid.to_i > 3100 or user_msg.length < 2 # 비어 있으면 광역시가 아님. 세종시는 제외! (세종시는 구가 없음.)
          res = Gusigun.where("townname LIKE ?", "%#{user_msg[0,2]}%")[0]
# ap res
          if res.nil? or user_msg.length < 2
            add_message = "#{user_msg} 는 찾을 수 없습니다.\n" 
            @temp_msg, @temp_key = nextfuncstep(add_message, @addr_menu, FUNC_STEP_RETRY)
          else
            user = User.find_by(user_key: user_key)

            user.sido = Sido.where(wiwid: res.wiwid).pluck(:wiwname)[0]
            user.sido_code = res.wiwid
            
            if res.wiwtypecode == "30" # 구가 있는 시
              user.sigun = res.guname # 시 명칭이 구네임에 들어가 있음. 헷갈림 주의!
              user.save
              address = user.sido.to_s + " " + user.sigun.to_s
              @temp_msg ,@temp_key = nextfuncstep(address, @addr_menu, FUNC_STEP_ADDRESS_GU)
            else
              user.sigun = res.townname
              user.gu = nil
              user.gusigun_code = res.towncode
              user.save
              address = user.sido.to_s + " " + user.sigun.to_s
              @temp_msg, @temp_key = nextfuncstep(address, @addr_menu, FUNC_STEP_ADDRESS_EMD)  
            end

          end
          
        else # 광역시 인 경우 이리루
          user = User.find_by(user_key: user_key)

          user.sido = Sido.where(wiwid: res.wiwid).pluck(:wiwname)[0]
          user.sido_code = res.wiwid
          user.sigun = nil
          user.save
          address = user.sido.to_s
          @temp_msg ,@temp_key = nextfuncstep(address, @addr_menu, FUNC_STEP_ADDRESS_GU)
        end
        
        
      elsif fstep == FUNC_STEP_ADDRESS_GU
        user = User.find_by(user_key: user_key)
        gu = user_msg.gsub(/\s/,"")
        res = Gusigun.where("wiwid = ? AND townname LIKE ?", "#{user.sido_code}", "%#{gu}%")[0]

        if res.nil? or user_msg.length < 2
          add_message = "#{user_msg} 는 찾을 수 없습니다.\n" 
          @temp_msg, @temp_key = nextfuncstep(add_message, @addr_menu, FUNC_STEP_RETRY)
        else
          user = User.find_by(user_key: user_key)
          user.gu = res.townname
          user.gusigun_code = res.towncode
          
          user.save
          
          address = user.sido.to_s + " " + user.sigun.to_s + " " + user.gu.to_s 
          @temp_msg, @temp_key = nextfuncstep(address, @addr_menu, FUNC_STEP_ADDRESS_EMD)
        end
        
      elsif fstep == FUNC_STEP_ADDRESS_EMD
        user = User.find_by(user_key: user_key)
        emd = user_msg.gsub(/\s/, "")
        
        res = Emd.where("towncode = ? AND emdname LIKE ?", "#{user.gusigun_code}", "%#{emd}%").pluck(:emdcode, :emdname)
        
        if res.size == 0
          res = Emd.where("towncode = ? AND findlist LIKE ?", "#{user.gusigun_code}", "%#{emd}%").pluck(:emdcode, :emdname)
        end
# ap res        
        if res.size == 0 or user_msg.length < 2
          add_message = "#{user_msg} 은 찾을 수 없습니다.\n" 
          @temp_msg, @temp_key = nextfuncstep(add_message, @addr_menu, FUNC_STEP_RETRY)
        elsif res.size > 1
          btn = Array.new
          res.each{|v| btn.push(v[1])}
          btn.push("이전")
          @temp_msg, @temp_key = nextfuncstep(@addr_menu, FUNC_STEP_ADDRESS_CONFIRM)
          @temp_key = @@key.getBtnKey(btn)
        else
          
          user = User.find_by(user_key: user_key)
          
          user.emd_code = res[0][0]
          user.emd = res[0][1]
          user.save
          address = user.sido.to_s + " " + user.sigun.to_s + " " + user.gu.to_s + " " + user.emd.to_s
          
          @temp_msg, @temp_key = init_state("#{address} 저장완료.",user_key)
        end
      elsif fstep == FUNC_STEP_ADDRESS_CONFIRM

          user = User.find_by(user_key: user_key)
          res = Emd.where(emdname: user_msg)[0]
# ap "Final btn >>>>>>"
# ap res          
          user.emd_code = res.emdcode
          user.emd = res.emdname
          user.save
          
          address = user.sido.to_s + " " + user.sigun.to_s + " " + user.gu.to_s + " " + user.emd.to_s
          @temp_msg, @temp_key = init_state("#{address} 저장완료.",user_key)
      else 
        # 잘못된 접근
        @temp_msg, @temp_key = init_state(user_key)
      end
    end
    
# ap "setAddress >>>>>>>"    
# ap @temp_msg
# ap @temp_key


    return @temp_msg, @temp_key
  end

####################################################
  
  def nextfuncstep(text="", menu, fstep)

# ap "nextfuncstep >>>>>"    
# ap text
# ap fstep
# ap menu.keys[fstep]
    user_key = params[:user_key] 
    indx = fstep == FUNC_STEP_RETRY ? @@user[user_key][:fstep][-1] : fstep
      
    msg = text == "" ? menu.keys[indx] : text.to_s + "\n" + menu.keys[indx].to_s # 전달 받은 TEXT 가 있는 경우 추가
    keytype = menu[msg]
    
    if fstep != FUNC_STEP_RETRY
      @@user[user_key][:fstep].push(fstep)
    end
    
    return msg, keytype
  end
####################################################

  def findCandidate(user_msg)
    user_key = params[:user_key]
    @sun_code = {
                 "시,도지사선거"=> "3",
                 "구,시,군의 장선거"=> "4",
                 "시,도의회의원선거"=> "5",
                 "구,시,군의회의원선거"=> "6",
                 "교육감선거"=> "11",
                 "홈"=> "90"
                }
    @ismsgBtn = false
    fstep = @@user[user_key][:fstep][-1]

    if user_msg == "홈"
      @temp_msg, @temp_key = init_state(user_key)
    else
      user = User.where(user_key: user_key)[0]
      
      if fstep == FUNC_STEP_INIT
        
        if user.sido.nil? or user.sido_code.length < 4 or !corr_address(user)
          text = (user.sido.nil? or user.sido == "") ? "주소를 등록해 주세요." : "#{user.sido} #{user.gu} #{user.sigun} #{user.emd}\n등록된 주소를 확인해 주세요."
          @temp_msg, @temp_key = init_state(text,user_key)
        else
          @temp_msg = "어떤 후보자를 찾고 있습니까?"  
          @temp_key = @@key.getBtnKey(@sun_code.keys)
          @@user[user_key][:fstep].push(FUNC_STEP_CHOICE_SGCODE)
        end
        
      elsif fstep == FUNC_STEP_CHOICE_SGCODE
        sgcode = @sun_code[user_msg]
# ap "후보자 찾기 >>>>>>"  
# ap sgcode
# ap user
        if user.sido_code.nil? or user.gusigun_code.nil? or user.emd_code.nil?
          @temp_msg, @temp_key = init_state("주소를 다시 한번 확인해 주세요.",user_key)
        else
          # tail_num = ["3","4","11"].include?(sgcode) ? "00" : "01"
          # midle_num = ["3","11"].include?(sgcode) ? "#{user.sido_code}" : "#{user.gusigun_code}" #( ["4","5","6"].include?(sgcode) ? "#{user.gusigun_code}" : "#{user.emd_code}" )
          
          sggurl = "http://info.nec.go.kr/main/main_election_jd_sgg.json?electionId=0020180613&sgTypeCode=#{sgcode}&emdCode=#{user.emd_code}"
# ap sggurl          
          sggresponse = RestClient.get(sggurl)
          sggparsed = JSON.parse(sggresponse)
          # ap "-------------"
          # ap sggurl
          # ap sggparsed
          # ap sggparsed["SggMap"][0]["CODE"]
       
          sggcode = sggparsed["SggMap"][0]["CODE"]
          
          # @url = "http://info.nec.go.kr/main/main_election_candidate.json?electionId=0020180613&sgTypeCode=#{sgcode}&sggCode=#{sgcode}#{midle_num}#{tail_num}&emdCode=#{user.emd_code}&startIndex=0&endIndex=9"
          @url = "http://info.nec.go.kr/main/main_election_candidate.json?electionId=0020180613&sgTypeCode=#{sgcode}&sggCode=#{sggcode}&emdCode=#{user.emd_code}&startIndex=0&endIndex=9"
          
          user = User.where(user_key: user_key)[0]
          user.url = @url
          user.save
          
          # homepage(fin_url)

          @m_url = "https://w-election-kimddo.c9users.io/homepage/result/#{user.id}"
          # @m_url = "http://52.15.121.230/homepage/result/#{user.id}" # for deploy

          # @m_url = urlshortener(@m_url)
          # @temp_msg = "#{@m_url} 입니다. "
          temp = Array.new
          temp.push(user_msg)
          temp.push(@m_url)
          
          @temp_msg = temp
          @ismsgBtn = true
          @temp_key = @@key.getBtnKey(@sun_code.keys)  
        end
      end
    end
    
    return @temp_msg, @temp_key, @ismsgBtn
  end
####################################################
## 투표소 

  def findPlace(user_key)
    
    user_key = params[:user_key]
    user = User.find_by(user_key: user_key)
    if user.sido.nil? or user.sido_code.length < 4
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
# ap placemap
      
      @temp_msg, @temp_key = init_state(placemap,user_key)
    end
  
    return @temp_msg, @temp_key  
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

  def urlshortener(url)
    require "bitly"
    
    bitly = Bitly::V3::Client.new(ENV["BITLY_ID"], ENV["BITLY_API_KEY"])
    
    res = bitly.shorten(url)
    
    return res.short_url
  end
##################################################
  def corr_address(user)

# ap "correct address >>>>>>>"
# ap user.sido_code[0,2]
# ap user.gusigun_code[0,4]
# ap user.emd_code[0,4]

    return  ((user.sido_code[0,2] == user.gusigun_code[0,2]) and 
            (user.gusigun_code[0,4] == user.emd_code[0,4])) ?  true : false

  end
end
