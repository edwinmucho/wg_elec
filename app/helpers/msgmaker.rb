module Msgmaker
     class Keyboard

        def getTextKey

            json = {
                "type": "text"
            }
            return json
        end
        
        def getBtnKey(*arg)

            json = {
              "type": "buttons",
                "buttons": []
            }

            arg.each do |a|
                json[:buttons] = a
            end

            return json

        end


    end

    class Message

        def getMessage(text)
            json = {
                "text": "#{text}"
            }
            return json
        end

        def getPicMessage(text,photo_url)

            json = {
                "text": text,
                "photo": {
                    "url": photo_url,
                    "width": 960,
                    "height": 960

                }
            }

            return json

        end

        def getLinkBtn(label, url)
            json = {
                "message_button":{
                    "label": label,
                    "url": url
                }
            }
        end
        
        def getMessageBtn(text,label,url)
            json = {
                "text": text,
                "message_button":{
                    "label": label,
                    "url": url
                }
            }
        end
        
        def getPictureBtn(photo_url,label,url)
            json = {
                "photo":{
                    "url": photo_url,
                    "width": 640,
                    "height": 480
                },
                "message_button":{
                    "label": label,
                    "url": url
                }
            }
        end
        
        def getMsgPicBtn(text,photo_url,label,url)
            json = {
                "text": text,
                "photo":{
                    "url": photo_url,
                    "width": 640,
                    "height": 480
                },
                "message_button":{
                    "label": label,
                    "url": url
                }
            }
        end
    end



end
