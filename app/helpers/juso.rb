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
ap sh
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

    class Func_step
        def find_el
            return n_step=1, result="시/도지사"
        end

        def find_sido

            return n_step=1, result="서울"
        end

        def find_gusigun(sido)

            return n_step=1, result="#{sido} 금천구"
        end

        def find_emd(gusigun)

            return n_step=1, result="#{gusigun} 독산동"
        end

        def go_home
            return n_step=90, result=""
        end

        def back_func
            return n_step=-1, result=""
        end
    end
end
