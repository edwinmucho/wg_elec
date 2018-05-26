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

    user = User.where(id: params[:user_id])[0]
    # url = @fin_url
    # url = "http://info.nec.go.kr/main/main_election_precandidate.json?electionId=0020180613&sgTypeCode=3&sggCode=3110000&emdCode=112111&startIndex=0&endIndex=9" 
    response = RestClient.get(user.url)
    @parsed = JSON.parse(response)
  end

end
