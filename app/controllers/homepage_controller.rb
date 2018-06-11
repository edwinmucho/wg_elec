class HomepageController < ApplicationController
    
  def index
    require "json"
    require "nokogiri"
    # require 'httparty'
    require 'rest-client'
    # send_json_url_to_homepage = KakaoController.new
    # send_json_url_to_homepage.send(:message)
    # ERB.render("result.html.erb",send_json_url_to_homepage.fin_url)

    # url = "http://info.nec.go.kr/main/main_election_precandidate.json?electionId=0020180613&sgTypeCode=3&sggCode=3110000&emdCode=112111&startIndex=0&endIndex=9" 
    url = @fin_url
    response = RestClient.get(url)
    @parsed = JSON.parse(response)
    # @code = @parsed["hbjMap"][0]["SG_TYPECODE"]
    # @name = @parsed["hbjMap"][0]["HBJNAME"]
    # @photo = "http://info.nec.go.kr/photo_20180613" + @parsed["hbjMap"][0]["IMAGE_FILE"]     
    # @party = @parsed["hbjMap"][0]["JDNAME"]     
    # @huboId = @parsed["hbjMap"][0]["HUBOID"]
    # @link = "http://info.nec.go.kr/electioninfo/precandidate_detail_info.xhtml?electionId=0020180613&huboId=" + @huboId.to_s
    
    # {"HBJNAME"=>"김문수(金文洙)", "EMDNAME"=>"신림동", "HBJGIHO"=>nil, "EMDID"=>112111, "SUB_SG_ID"=>320180613, "SG_ID"=>20180613, "IMAGE_FILE"=>"/Sd1100/Sgg3110000/Hb100129583/gicho/100129583.JPG", "WIWNAME2"=>"종로구", "HUBOID"=>100129583, "RN"=>1, "CNT"=>8, "JDNAME"=>"자유한국당", "SG_TYPECODE"=>3,

  end
  
  def result
    require "json"
    require "nokogiri"
    # require 'httparty'
    require 'rest-client'

    @user = User.where(id: params[:user_id])[0]

    if not @user.gusigun_code.nil?
      @cu = {}
      jd_list = Jdcheer.where("gsg_code = ?", "#{@user.gusigun_code}").pluck(:jdname, :cheerup)
      if not jd_list.nil?
        jd_list.each do |jd, cu|
          @cu[jd] = cu
        end
      end
    end
    # url = @fin_url
    # url = "http://info.nec.go.kr/main/main_election_precandidate.json?electionId=0020180613&sgTypeCode=3&sggCode=3110000&emdCode=112111&startIndex=0&endIndex=9" 
    response = RestClient.get(@user.url)
    @parsed = JSON.parse(response)
  end
  
  def cheerup_babe
    id = params[:user_id]
    jdname = params[:jdname]
    sgtype = params[:sgtype]
    hbname = params[:hbname]

ap jdname
ap sgtype    
ap hbname    
    # 유저 확인.
    user = User.find(id)
    if not user.nil?
      
      # 응원한 정당이 DB에 있는지 확인
      if not Jdcheer.where("gsg_code = ? AND jdname = ? AND hubo = ?", user.gusigun_code, jdname, hbname).exists? # 없으면 새로 만듬.
        gsg_id = Gusigun.where(towncode: user.gusigun_code).pluck(:id)[0] # 유저의 지역을 저장하기 위해.
        
        cheer = Jdcheer.create(gusigun_id: gsg_id, gsg_code: user.gusigun_code, jdname: jdname, ele_code: sgtype, hubo: hbname, cheerup: 1)
      else  
        cheer = Jdcheer.where("gsg_code = ? AND jdname = ? AND hubo = ?", user.gusigun_code, jdname, hbname)[0]
      end
      
      if user.tdy_cnt.nil? or user.ttl_cnt.nil?
        user.tdy_cnt = 1
        user.ttl_cnt = 1
      else
        user.tdy_cnt += 1
        user.ttl_cnt += 1
      end
      cheer.cheerup += 1
      
      cheer.save
      user.save
    end

    # redirect_to "/homepage/result/#{id}"
  end
  
  def cheerup_result
    @jdlist = Jdcheer.all
    @jdlist1 = Jdcheer.group(:gusigun_id,:jdname).sum(:cheerup)
    @sido_option = Sido.all
    @gsg_option = Gusigun.where(wiwid: params[:sido_id])
    @gsg = {}
    Gusigun.all.pluck(:townname, :towncode).each do |name, code|
      @gsg[code] = name
    end
    # 구/시군 기준 정당 별 카운트
    @local_JD_cheerlist = Jdcheer.group(:gusigun_id, :jdname).sum(:cheerup)
  end

  def second_dropdown
    sido_code = params[:sido_code]
    
    sido = Sido.where(wiwid: sido_code)[0]
    unless sido.nil?
      @second_option = sido.gusigun.pluck(:towncode, :townname)
      respond_to do |f|
          f.js
      end
    end
  end
  
  def cheerup_graph
    sido_code = params[:sido_code]
    gsg_code = params[:gusigun]
    
    # 전국 단위 확인.
    if sido_code.nil? or sido_code.length == 0
      ap "전국"
      @cheer_list = Jdcheer.group(:jdname).sum(:cheerup).sort_by{|x,y| -y}
    # 광역시/ 도별 확인.
    elsif gsg_code.nil? or gsg_code.length == 0
    ap "시도"
      temp_list = Jdcheer.group(:gsg_code, :jdname).sum(:cheerup).sort_by{|x,y| -y}
      temp={}
      
      temp_list.each do |local, cheer|
        
        if sido_code[0,1] == local[0][0,1]
          if temp[local[1]].nil?
            temp[local[1]] = cheer
          else
            temp[local[1]] = temp[local[1]] + cheer
          end
        end
      end
      
      @cheer_list = temp.to_a
    else
      ap "지역"
      gsg = Gusigun.where(wiwid: sido_code, towncode: gsg_code)[0]
      
      unless gsg.nil?
        @cheer_list = gsg.jdcheer.group(:jdname).sum(:cheerup).sort_by{|x,y| -y}
        ap @cheer_list
        respond_to do |f|
            f.js
        end
      end
    end
    
  end
end
