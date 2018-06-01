require 'nokogiri'
require 'open-uri'
require 'rest-client'
require 'awesome_print'
require "json"

module Juso
    class JsSave
        def sidosave
            gongtong = "http://info.nec.go.kr/main/"
            url = gongtong+"main_election_sido_map.json?electionId=0020180613"
            result = RestClient.get url
            result=JSON.parse(result)
            return result
        end

        def gusigunsave(wiwid)
            gongtong = "http://info.nec.go.kr/main/"
            url = gongtong+"main_election_gusigun_map.json?electionId=0020180613&parentCityCode="+wiwid
            result = RestClient.get url
            result=JSON.parse(result)
            return result
        end

        def emdsave(tc)
            gongtong = "http://info.nec.go.kr/main/"
            url = gongtong + "main_election_emd_map.json?electionId=0020180613&townCode="+ tc
            result = RestClient.get url
            result=JSON.parse(result)

            return result
        end


        def bjsave(file)
            require "csv"

            sh = Hash.new
            dh = Hash.new

            CSV.foreach(file) do |s, h, b|
                sh = self.arrinhash(sh, s, h)

                if not b.nil?
                    dh = self.arrinhash(dh, "#{s} #{h}", b)
                end
            end

            if dh.size > 0
                sh.each do |k, v|
                    sh[k] = v.uniq
                    sh[k].each do |d|
                        tmp = Hash.new
                        idx = sh[k].index(d)
                        tmp[d] = dh["#{k} #{d}"]
                        # ap tmp
                        sh[k][idx] = tmp
                        # ap dh["#{k} #{d}"]
                    end
                end
            end
# ap sh
            return sh
        end

        def arrinhash(hsh, hk, val)
            arr = Array.new

            if hsh[hk].nil?
                arr.push(val)
                hsh[hk] = arr
            else
                hsh[hk].push(val)
            end

            return hsh
        end

    end
    
    class JsFind
        
        def search_addr(keyword)

            url = "https://m.search.daum.net/search?w=tot&nil_mtopsearch=btn&DA=YZR&q=#{keyword}"
            uri = URI.encode(url)
            
            doc = Nokogiri::HTML(open(uri),nil,'utf-8')
            
            # 다음에서 출력되는 주소 저장
            full_address, detail_dong, guess_dong = daum_map(keyword)
# ap "search_addr >>>>"            
# ap full_address
# ap detail_dong
# ap guess_dong
            # 출력되는 주소를 도/시/구/동 으로 나누어 주는 부분.
            addr = split_address(full_address) if full_address.length != 0
# ap "addr>>>"
# ap addr

            # 입력한 동과 출력된 동이 다른경우 같게 맞춰주는 작업. (도로명 주소는 해당사항 없음.)
            chk_diff = keyword.scan(/[0-9]+[동|가]/)[0].to_s # 독산1동에대해 자세히 검사하는 경우. 최종 주소에 독산동이라고만 표기됨. 해당부분을 바로 잡고자 수정하는 부분.
# ap "chk_diff >>>"
# ap chk_diff
# ap addr[:emd].include?chk_diff
            if chk_diff.length != 0 and not addr[:emd].include?chk_diff
                addr[:emd] = addr[:emd].gsub(/[동|가]/,chk_diff)
            end
# ap "emd >>>"            
# ap addr[:emd]            
            # 동 정보가 비어있는 경우 detail 이나 guess 의 값을 전달.
            if addr[:emd].nil? or addr[:emd] == ""
                emd = (detail_dong.size != 0) ? detail_dong.uniq : guess_dong.uniq
                if emd.size == 1
                    addr[:emd] = emd[0]
                else
                    addr[:emd] = nil
                end
            end
# ap "addr>>>>"            
# ap addr
            return addr
    
        end
        
        def split_address(full_addr)
            temp = {
                :sido => nil,
                :gu => nil,
                :sigun => nil,
                :emd => nil
            }
            temp_addr = full_addr.split(' ')

            temp[:sido] = temp_addr.shift
            
            temp_addr = temp_addr.join(' ')

            temp[:gu] = temp_addr.scan(/[가-힣]+구 /)[0]
            temp[:sigun] = temp_addr.scan(/[가-힣]+[시|군] /)[0]
            temp[:emd] = temp_addr.scan(/[가-힣0-9]+[읍|면|동|가]$/)[0]
            
            temp.each {|k,v| temp[k] = v.gsub(/\s/, '') if not v.nil? }
            
            return temp
        end
        
        def daum_map(keyword)
 
            url = "https://m.search.daum.net/search?w=tot&nil_mtopsearch=btn&DA=YZR&q=#{keyword}"
            uri = URI.encode(url)
            doc = Nokogiri::HTML(open(uri),nil,'utf-8')
            
            raw_data1 = doc.css("div#addressColl strong").to_s
            raw_data2 = doc.css("dd#addressCollRelatedAddrBtn").to_s
            raw_data3 = doc.css("#addressColl > div.coll_cont > span").to_s

            data1 = raw_data1.scan(/[가-힣0-9]+/).join(' ').gsub(/[가-힣0-9]+[길|로]$/,"") # 도로명 주소는 제거.
            data1 = data1.gsub(/ [0-9]+/,"") # 번지 숫자 제거
            data2 = raw_data2.scan(/[가-힣0-9]+[동|가]+/) # 자세히 입력 되었을때
            data3 = raw_data3.scan(/[가-힣]+/).join(' ').scan(/[가-힣]+동/)  # 불친절하게 입력했을때

# ap "raw data >>>>>>>"            
# ap raw_data1
# ap data1
# ap "----------"
# ap raw_data2
# ap data2
# ap "----------"
# ap raw_data3
# ap data3
# ap "----------"
            
            return data1, data2, data3
        end
    end

end
