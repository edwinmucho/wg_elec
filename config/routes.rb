Rails.application.routes.draw do
  get 'homepage/index' => 'homepage#index'
  get 'homepage/result/:user_id' => 'homepage#result'
  get 'kakao/homepage' => 'kakao#homepage'
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  get '/keyboard' => 'kakao#keyboard'

  post '/message' => 'kakao#message'

  post '/friend' => 'kakao#friend_add'
  delete '/friend' => 'kakao#friend_del'

  delete '/chat_room/:user_key' => 'kakao#chat_room'

  get 'db/check_pw' => 'dbsave#check_pw'
  get 'db/loginpage' => 'dbsave#loginpage'
  get 'db/mainpage' => 'dbsave#mainpage'
  get 'db/destroypage' => 'dbsave#destroypage'
  get 'db/saveemd' => 'dbsave#saveemd'
  get 'db/savegsg' => 'dbsave#savegsg'
  get 'db/savesido' => 'dbsave#savesido'
  
  get '/dkdkdlwkddlqslek' => 'dbsave#loginpage'
  get '/dkdkdlwkd/dlqslek_sido' => 'dbsave#savesido'
  get '/dkdkdlwkd/dlqslek_gsg' => 'dbsave#savegsg'
  get '/dkdkdlwkd/dlqslek_emd' => 'dbsave#saveemd'
  post '/dkdkdlwkd/dlqslek_des' => 'dbsave#destroy_db'
  # match ':controller(/:action(/:id))', via: [:get, :post, :patch]
  # get '/hello/view' => 'hello#view'
end
