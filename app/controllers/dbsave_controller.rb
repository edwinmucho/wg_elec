class DbsaveController < ApplicationController
    
    def loginpage
        session.clear
    end

    def check_pw
        if params[:pw] == "dnjfrkscotqht1!"
            session[:login] = true
            redirect_to '/db/mainpage'
        else
            redirect_to '/db/loginpage'
        end
    end
    
    def mainpage    
        if !session[:login]
            redirect_to '/db/loginpage'
        end
        @sido_cnt = Sido.all.count
        @gsg_cnt = Gusigun.all.count
        @emd_cnt = Emd.all.count
    end
    
    def destroypage
        if !session[:login]
            redirect_to '/db/loginpage'
        end
        @sido_cnt = Sido.all.count
        @gsg_cnt = Gusigun.all.count
        @emd_cnt = Emd.all.count
        
    end
    
    def destroy_db
        # ap params[:target]
        begin
            if params[:target] == "sido"
                Sido.delete_all
            elsif params[:target] == "gsg"
                Gusigun.delete_all
            elsif params[:target] == "emd"
                Emd.delete_all
            else
            end
        
        rescue
            flash[:notice] = '뽀린키 때매 읍면동 1빠/구시군 2빠/시도 3빠로 지우게나!'
        end

        redirect_to '/db/destroypage'        
    end
    
    def savesido
        
        if !session[:login]
            redirect_to '/db/loginpage'
        end
        
        dbsave = Juso::JsSave.new
        
        @msg = "Sido Save Complete!!"
        if Sido.all.count > 10
            @msg = "Already Saved!"
            return
        end
        
        sd = dbsave.sidosave
        file = "./sido.csv"
        sdn = dbsave.bjsave(file)
        
        sd["cityCodeMap"].each do |city|
        # ap city["WIWNAME"]
        Sido.create(wiwid: city["WIWID"], wiwname: city["WIWNAME"], findlist: sdn[city["WIWNAME"]])
        end
        
        redirect_to '/db/mainpage'
    end
    
    def savegsg
        
        if !session[:login]
            redirect_to '/db/loginpage'
        end
        
        
        dbsave = Juso::JsSave.new
        sido = Sido.all
        @msg = "Gusigun Save Complete!!"
        
        if Gusigun.all.count > 10
            @msg = "Already Saved!"
            return 
        end
        
        sido.each do |si|
            js = dbsave.gusigunsave(si.wiwid)
            
            js["gusigunCodeMap"].each do |gsg|
            
            Gusigun.create(sido_id: si.id, wiwid: si.wiwid, wiwtypecode: gsg["WIWTYPECODE"].to_s,
                towncode: gsg["CODE"], townname: gsg["NAME"],
                guname: gsg["GUNAME"])
            end
        end
        ap Gusigun.exists?
        if not Gusigun.exists? or (Gusigun.all.count < 10)
            flash[:notice] = '시도 먼저 저장 하셨는가?? 확인해보시게'
        end
        
        redirect_to '/db/mainpage'
    end
    
    def saveemd
        
        if !session[:login]
            redirect_to '/db/loginpage'
        end
        @glist = []
        @nilist = []
        @clist =[]
        dbsave = Juso::JsSave.new
        gusigun = Gusigun.all
        
        if Emd.all.count > 10
            @glist.push("Already Saved!")
            return
        end

        file = "./emd_501.csv"
        juso = dbsave.bjsave(file)

        ch_si = {"수원시권선구" => "수원시장안구",
              "고양시덕양구" => "고양시일산동구",
              "용인시기흥구" => "용인시수지구",
              "천안시동남구" => "천안시서북구",
              "고양시일산동구" => "고양시일산서구",
              "천안시서북구" => "천안시동남구",
              "전주시완산구" => "전주시덕진구"}
        ch_tcode = {
                "수원시권선구" => "4101", # 수원시장안구 율천동
                "고양시덕양구" => "4121", # 고양시일산동구 식사동
                "고양시일산동구" => "4122", # 고양시일산서구 일산2동
                "용인시기흥구" => "4136", # 용인시수지구 죽전1동, 죽전2동
                "천안시서북구" => "4418", #천안시동남구 신방동
                "천안시동남구" => "4417", #천안시서북구 성정1동, 성정2동
                "전주시완산구" => "4502" # 전주시덕진구 인후3동
                }
        nec_info = {
                "수원시권선구" => ["율천동"],
                "고양시덕양구" => ["식사동"],
                "고양시일산동구" => ["일산2동"],
                "용인시기흥구" => ["죽전1동", "죽전2동"],
                "천안시서북구" => ["신방동"],
                "천안시동남구" => ["성정1동","성정2동"],
                "전주시완산구" => ["인후3동"]
                }


        # transaction 을 넣은 이유: 없으면 503인가 502 인가 에러남 타임아웃 때문에 생기는 문제로 사료됨.
        # transaction 사이에 넣으면 해당 코드가 끝나길 기다리고 나서 다음 단계로 넘어가기에 타임아웃 발생 안함.
        ApplicationRecord.transaction do
            gusigun.each do |gsg|
                js = dbsave.emdsave(gsg.towncode)
                
                js["emdMap"].each do |emd|
                    arr = Array.new
                    if juso[gsg.townname].nil?
                        @glist.push(gsg.townname)
                        next
                    end
                    
                    tname = ""
                    if not nec_info[gsg.townname].nil? and nec_info[gsg.townname].include?(emd["NAME"])
                        tname = ch_si[gsg.townname]
                    else
                        tname = gsg.townname
                    end
                    
                    juso[tname].each do |v|
                        if not v[emd["NAME"]].nil?
                          arr = v[emd["NAME"]]
                        end
                    end
                    
                    # ap nec_info[gsg.townname] if not nec_info[gsg.townname].nil?
                    if not nec_info[gsg.townname].nil? and nec_info[gsg.townname].include?(emd["NAME"])
                        # ap "   #{gsg.townname}"
                        # ap "or  : #{nec_info[gsg.townname]}" # 동이름
                        # ap "emd : #{emd["NAME"]}"
                        # ap "code: #{ch_tcode[gsg.townname]}" # 저장될 코드
                        # ap "--------------"
                        tmp = gusigun.find_by("towncode": ch_tcode[gsg.townname])
                        # ap gsg.id
                        # ap tmp.id
                        Emd.create(gusigun_id: tmp.id, towncode: ch_tcode[gsg.townname], emdcode: emd["CODE"], emdname: emd["NAME"], findlist: arr )
                    end
                    
                    Emd.create(gusigun_id: gsg.id, towncode: gsg.towncode, emdcode: emd["CODE"], emdname: emd["NAME"], findlist: arr )
                    
                    if arr == [] or arr.nil?
                        @glist.push(juso[gsg.townname])
                        @nilist.push(emd["NAME"])
                        @clist.push(emd["CODE"])
                    end
                end
            end
        end
        if not Emd.exists? or (Emd.all.count < 10)
            flash[:notice] = '시도 / 구시군은 저장 하셨는가?? 확인해보시게'
        end
        redirect_to '/db/mainpage'
    end       
end
