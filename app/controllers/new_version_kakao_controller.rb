require 'msgmaker'
require 'juso'

class KakaoController < ApplicationController
  
  @@key = Msgmaker::Keyboard.new
  @@msg = Msgmaker::Message.new

  # 메뉴 종류
  MENU_STEP_FIND_CANDI    = "후보자 찾기"
  MENU_STEP_ADD_ADDRESS   = "내 주소등록/수정"
  MENU_STEP_CHECK_ADDRESS = "내 주소 확인"


  
  DEFAULT_MESSAGE = "메뉴를 골라 주세요."

  # 펑션 종류
  FUNC_STEP_INIT             = 0

  # 주소 저장 스텝
  FUNC_STEP_ADDRESS_SIGUN    = 1
  FUNC_STEP_ADDRESS_GU       = 2
  FUNC_STEP_ADDRESS_EMD      = 3
  FUNC_STEP_ADDRESS_CONFIRM  = 4

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
ap "User stat >>>>"
ap @@user

    # menu step 변경 하는 부분.
    if @@user[user_key][:mstep] == "main"
      @@user[user_key][:mstep] = user_msg if @next_keyboard[:buttons].include? user_msg
    end



    # 각 메뉴 진입.
    case @@user[user_key][:mstep]
    
      when MENU_STEP_ADD_ADDRESS
        @next_msg, @next_keyboard = setAddress(user_msg)
      when MENU_STEP_FIND_CANDI
        @next_msg, @next_keyboard = findCandidate(user_msg)
      when MENU_STEP_CHECK_ADDRESS
        @next_msg, @next_keyboard = checkAddress(user_key)
      else
        
      end


    # ap " result >>>>>>"
    # ap @next_msg
    # ap @next_keyboard
    
    msg = @next_msg
    basic_keyboard = @next_keyboard
    
    result = {
      message: @@msg.getMessage(msg.to_s),
      keyboard: basic_keyboard
    }

    render json: result
  end

  def friend_add
    User.create(user_key: params[:user_key], chat_room: 0)
   
    @@user[user_key] = 
    {
      :mstep => @mstep = "main",
      :fstep => @fstep = [FUNC_STEP_INIT]
    }
    render nothing: true
  end

  def chat_room
    user = User.find_by(user_key: params[:user_key])
    user.chat_room += 1
    user.save
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
    main_menu = [MENU_STEP_FIND_CANDI,MENU_STEP_ADD_ADDRESS, MENU_STEP_CHECK_ADDRESS]
    
    default_msg = DEFAULT_MESSAGE   # "메뉴를 골라 주세요."
    default_key = @@key.getBtnKey(main_menu)
    
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
        @temp_msg, @temp_key = nextfuncstep(@addr_menu, @@user[user_key][:fstep][-1])
    elsif user_msg == "홈"
        @temp_msg, @temp_key = init_state(user_key)
    else
      if fstep == FUNC_STEP_INIT
        @temp_msg = @addr_menu.keys[fstep]
        @temp_key = @addr_menu[@temp_msg]
        
        
        @@user[user_key][:fstep].push(FUNC_STEP_ADDRESS_SIGUN)
        
      elsif fstep == FUNC_STEP_ADDRESS_SIGUN
        
        res = Sido.where("wiwname LIKE ?", "%#{user_msg[0,2]}%")[0]

        if res.nil?  or res.wiwid == "5100" or user_msg.length < 2 # 비어 있으면 광역시가 아님. 세종시는 제외! (세종시는 구가 없음.)
          res = Gusigun.where("townname LIKE ?", "%#{user_msg[0,2]}%")[0]

          if res.nil? or user_msg.length < 2
            add_message = "#{user_msg} 는 찾을 수 없습니다.\n" 
            @temp_msg, @temp_key = nextfuncstep(add_message, @addr_menu, FUNC_STEP_ADDRESS_SIGUN)
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
          user.save
          address = user.sido.to_s
          @temp_msg ,@temp_key = nextfuncstep(address, @addr_menu, FUNC_STEP_ADDRESS_GU)
        end
        
        
      elsif fstep == FUNC_STEP_ADDRESS_GU
        user = User.find_by(user_key: user_key)
        gu = user_msg.gsub(/\s/,"")
        res = Gusigun.where("wiwid = ? AND townname LIKE ?", "#{user.sido_code}", "%#{gu}%")[0]
# ap "구 찾기 >>>>>>>"        
# ap user.sido_code
# ap gu
# ap res
        if res.nil? or user_msg.length < 2
          add_message = "#{user_msg} 는 찾을 수 없습니다.\n" 
          @temp_msg, @temp_key = nextfuncstep(add_message, @addr_menu, FUNC_STEP_ADDRESS_GU)
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
          @temp_msg, @temp_key = nextfuncstep(add_message, @addr_menu, FUNC_STEP_ADDRESS_EMD)
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
          
          @temp_msg, @temp_key = init_state(user_key)
          @temp_msg = "#{address} 저장완료.\n" + @temp_msg
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
          @temp_msg, @temp_key = init_state(user_key)
          @temp_msg = "#{address} 저장완료.\n" + @temp_msg
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
    msg = text == "" ? menu.keys[fstep] : text.to_s + "\n" + menu.keys[fstep].to_s # 전달 받은 TEXT 가 있는 경우 추가
    keytype = menu[msg]
    
    @@user[user_key][:fstep].push(fstep)
    
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
    fstep = @@user[user_key][:fstep][-1]
    
    if user_msg == "홈"
      @temp_msg, @temp_key = init_state(user_key)
    else
      if fstep == FUNC_STEP_INIT
        @temp_msg = "어떤 후보자를 찾고 있습니까?"  
        @temp_key = @@key.getBtnKey(@sun_code.keys)
        @@user[user_key][:fstep].push(FUNC_STEP_CHOICE_SGCODE)
        
      elsif fstep == FUNC_STEP_CHOICE_SGCODE
        sgcode = @sun_code[user_msg]
        user = User.where(user_key: user_key)[0]
  
# ap "후보자 찾기 >>>>>>"  
# ap sgcode
# ap user
        if user.sido_code.nil? or user.gusigun_code.nil? or user.emd_code.nil?
          @temp_msg, @temp_key = init_state(user_key)
          @temp_msg = "주소를 다시 한번 확인해 주세요. \n" + @temp_msg
        else
          tail_num = ["3","4","11"].include?(sgcode) ? "00" : "01"
          midle_num = ["3","11"].include?(sgcode) ? "#{user.sido_code}" : "#{user.emd_code}"
    
          fin_url = "http://info.nec.go.kr/main/main_election_precandidate.json?electionId=0020180613&sgTypeCode=#{sgcode}&sggCode=#{sgcode}#{midle_num}#{tail_num}&emdCode=#{user.emd_code}&startIndex=0&endIndex=9"
          
          @temp_msg = " #{fin_url} 입니다. "
          @temp_key = @@key.getBtnKey(@sun_code.keys)  
        end
      end
    end
    
    return @temp_msg, @temp_key
  end

####################################################
  def checkAddress(user_key)
    user = User.where(user_key: user_key)[0]
    
    @temp_msg, @temp_key = init_state(user_key)
    
    if user.sido.nil?
      @temp_msg = "저장된 주소가 없습니다.\n" + @temp_msg
    else
      @temp_msg = "주소: #{user.sido} #{user.sigun} #{user.gu} #{user.emd} \n" + @temp_msg
    end
  
    return @temp_msg, @temp_key  
  end
  
end
