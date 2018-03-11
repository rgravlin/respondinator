ENV['RACK_ENV'] = 'test'

require_relative '../app/respondinator.rb'
require 'rspec'
require 'rack/test'

set :environment, :test

RSpec.describe 'Respondinator' do
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  it "says Route not found" do
    get '/'
    expect(last_response).to be_ok
    expect(last_response.body).to eq('{"error":"Route not found"}')
  end

  it "creates a Route called hello" do
    headers = { "CONTENT_TYPE" => "application/json" }
    post "/addme", '{ "path": "/hello", "response": "world"}', headers
    expect(last_response).to be_ok

    parsed_response = JSON.parse(last_response.body)
    expect(parsed_response.size).to eq(3)
    expect(parsed_response['path']).to eq('/hello')
    expect(parsed_response['response']).to eq('world')
  end

  it "says world" do
    get '/hello'
    expect(last_response).to be_ok
    expect(last_response.body).to eq('world')
  end    

  it "says Key failure" do
    headers = { "CONTENT_TYPE" => "application/json" }
    put "/addme", '{ "path": "/hello", "response": "world", "key": "c8c30f00-5956-4560-a14c-bdb4234ed69b"}', headers
    expect(last_response.status).to eq(403)

    parsed_response = JSON.parse(last_response.body)
    expect(parsed_response.size).to eq(1)
    expect(parsed_response['error']).to eq('Key failure')
  end

  it "says Not JSON" do
    headers = { "CONTENT_TYPE" => "application/json" }
    post "/addme", '{ "path": "/hello",, "response": "world"}', headers
    expect(last_response.status).to eq(406) 

    parsed_response = JSON.parse(last_response.body)
    expect(parsed_response.size).to eq(1)
    expect(parsed_response['error']).to eq('Not JSON')
  end

  it "says Incorrect keys" do
    headers = { "CONTENT_TYPE" => "application/json" }
    put "/addme", '{ "path": "/hello", "response": "world"}', headers
    expect(last_response.status).to eq(406)
    
    parsed_response = JSON.parse(last_response.body)
    expect(parsed_response.size).to eq(1)
    expect(parsed_response['error']).to eq('Incorrect keys')
  end

  it "says Key failure" do
    headers = { "CONTENT_TYPE" => "application/json" }
    put "/addme", '{ "path": "/hello", "response": "world", "key": "1"}', headers
    expect(last_response.status).to eq(403)

    parsed_response = JSON.parse(last_response.body)
    expect(parsed_response.size).to eq(1)
    expect(parsed_response['error']).to eq('Key failure')
  end

  it "says Too many keys" do
    headers = { "CONTENT_TYPE" => "application/json" }
    put "/addme", '{ "path": "/hello", "response": "world", "key": "1", "key2": "1"}', headers
    expect(last_response.status).to eq(406)

    parsed_response = JSON.parse(last_response.body)
    expect(parsed_response.size).to eq(1)
    expect(parsed_response['error']).to eq('Too many keys')
  end

  it "says Restricted route" do
    headers = { "CONTENT_TYPE" => "application/json" }
    post "/addme", '{ "path": "/addme", "response": "hello"}', headers
    expect(last_response.status).to eq(406)

    parsed_response = JSON.parse(last_response.body)
    expect(parsed_response.size).to eq(1)
    expect(parsed_response['error']).to eq('Restricted route')
  end

  it "says Unacceptable route" do
    headers = { "CONTENT_TYPE" => "application/json" }
    post "/addme", '{ "path": "hello", "response": "world"}', headers
    expect(last_response.status).to eq(406)

    parsed_response = JSON.parse(last_response.body)
    expect(parsed_response.size).to eq(1)
    expect(parsed_response['error']).to eq('Unacceptable route')
  end

  it "says Invalid method for route" do
    headers = { "CONTENT_TYPE" => "application/json" }
    post "/hello", '{ "path": "/hello", "response": "world"}', headers
    expect(last_response.status).to eq(406)

    parsed_response = JSON.parse(last_response.body)
    expect(parsed_response.size).to eq(1)
    expect(parsed_response['error']).to eq('Invalid method for route')
  end

  it "says DBAG detected!" do
    headers = { "CONTENT_TYPE" => "application/json" }
    post "/addme", ' []', headers
    expect(last_response.status).to eq(406)

    parsed_response = JSON.parse(last_response.body)
    expect(parsed_response.size).to eq(1)
    expect(parsed_response['error']).to eq('DBAG detected!')
  end  

  it "says Content-Length invalid" do
    headers = { "CONTENT_TYPE" => "application/json" }
    post "/addme", '{ "path": "/hello", "response": "7f002f69a4f1ac0609ae160567dc5f0b80d834c1885652b75987668b024259a1c099259bac25e259af99f1839e0a9892e2834a2f1440c5644086ec47cca8c182669412ff6d271a4c96564bc3c393a3b3f83db1d66d5ccfd03c5e9a46627c22c6fc6032aa86ed518907e69bcfa26450a22f6e65fc03cabaa10f075fa79b9579096764038984a4f0c0dfae69375dceb9596e510cce6855852abf6bfc667c5228fbbbb7f7eccd2ff83b477d1bfa0201334dc9c974075428955fb91ecc53d54ebc74513ffc0b36249a7d8e7fdb6c7d4126b25b94aceef7922c3c61565fc2fc54f805fdcfe92ebddd9afd689e73b44626ed68dd320471527bc242f81050a070625f5c6f3e34b2eef35078a422f9148466ecc6303cfe6e88c065007c9035555588f4179e3d1533a0cb7ebedb72c9f3f3ac8eb80983e047489eee2fe39c5bb95b92d471cedc447b402764da2197e1e006922dd75ee2652f534ae9e9c60a16fdae90ac8e5fe49d5e61cf114160d7dd5dbaaeacb5c5853c1b5134cf6fb042e478ceab30500bcfeed08efadce9293a10a55340848166eab9876f25a585ae4ebb4f8fbbccca8d97fe22b7f50bcd5921a5254acef967df6191728e3cc29651ebe720eb9953acce3baac2fc578c05c9229d6a78a834ba4f0092115b1ccc398adf2fa4eec28f57f23d0c08ad068bf5778c55959bb67c2daf97bf280c838113df44dd0c0525fca916650e98461e883be00e84c915009fd6a34e8c6c9213e3a9109e06b748714d15b6e7a04bf5a801ca8aed1815337d4a059761f30525bc5f0eaa5d7912c9ea47df851e84ca6b463b2a70e72f898c40cf956ecdcc1039fdebde2e4357eb0b819f250b0de6b28e94691c20e2e7c0b31ea6aef2eed1fe750d7b4e75683ce998e1b3cb186335f2a8b44be2ec5429b261fe1d8f9f6871ec0c3ebbd928bca8b52ac46a444f26f9bc28296ffd6cbb66704db6fecd51e4cb9a620944970e6229dc0e62623625cb801ab7f08c3f37f7fb5b21871d8add531d42a4f5107dd7150ad2fb5c534796a191c71bbd26643b82cc58f172fe06c899f5f9008aa8e142e21e0e4378badaa30b1203ca458be0167a4225516be15b5e4b2fe6f2b861d7f77ab0bd6510cae58a8eaf860c37f95a81bdaa0f8b5f0b5158385c49a584485fa02e327c31b229e01cd9bb044454fe83eab62b7db02fccc664db14b0353ad2afc0c558c70450c1bd8df8de5d2399f3c3dfcc1c87557216e858c6704b1613e1e3e0780376a0fdc166fec9a34657550baed1adf72108ad244c57f353d79d50992f118bd76249b175e5166948ec8de9a0ae6f7ba8112e2336e7df9e1edaf4ce2f4fd8cf5452575d20043c6d8d7a066b516f3aef09a0d783b4b126d465a2dd4b3171d376f20497151ae03239a81bc4e7eb1453ed558c6579dedea678ab5fc4ac34928808c2f3687872a4b24486fdfa4435f3deeea83704ad4b901562792d0f48676804243f1678be597d97843e2603155dffcb1e05d4f6a99d7d68e70633aa582e1bcc973b6d65c85209aa59e890d3a9048ea38bb0883b7424f85b335c9348f894ae56905f23e74fb5df63159e9d557d42389e2bac4cb3fe7a1329684d16286ba88d1db6a14d19d8b540dd363e100b4f31eff23b3e7d51e6e46302b3dbbbe620d5a5f37237a671cf068497c31ea6bd6923fbc07ea0aab86fd4ed919d73c54fc2c1af9bdd08713068a3c55edff6a7f7915c5329e4b43dd39771170a91c8e7ca28a5e75297e1888abcddcbbe6cf397e425a3461bea32edd8181dc427ba02255882b61833813cd490527ec41b15555208e61fe18f89bc0c53c808a1d6a5db5a9cb63bdc99d4a3b3feff33174239448d9b7a74f8f4cc7b5c16cc20a44f47691a82fabfa8cc383fc292ba79a036aeb76f0861b97a9db717d7a569f440ca2280bc6c6d78f450371d986461e4a0d5c857571eb2ebf75b78dfe43c6b7bd213107a6534166ef0b6f003de2eca581460e31c6c08d181e9496e25b8be0710caa801db1fdc4033ffb94f34801ad88db021fe80264b0a05198a9f1846e219be8e155b0c0663b6063392b2341e1a5f1f171781a1f174ae2379598a852238a9d6fd396bf5c725a00222cda3c2e218f49d40a29a477632d5525104c6e4a352d15b65aba8009323dc9c9fbe22e689e11afd04a9087dfcc9e9ebdf1ef90d9c37a9c879a672d60fcd60a0b23e2fc5bd579fae6efd0665a62f04f26df30504307e6ecbb525db79a64dc8ea3bb4201290b1050fb9830c1977355bdfbcfe46ead3edb3830de14b3654b67ba661aca0f8587484fd93ba8839f759f5751c01836d767c79c05741721a220578ff5477d785016cb23f1f9fea059613b3714da5275033a822be6d63d25faddf9c98ebebca34d8aaadf6948c34f328c37f74583173014af31caf5d675680aa66e9e0345dcb0b25981623e3701d62f84e885ac41e1c36f45738810260cb18e3fdcf847caf5f4a0309f50ce669008cd0d666d373782c84d42c2aba460c6a219dbbd2452de119c3588f0ca9355401615a7eb667e2b536b9d61954abc6979fea9d6c9ea7648e49df2481b616bf68ae0ab2dabdc718d96d5d99cdd3b82f62409ef326baaaba0cc93c0ff4041c8f9f635eb843b4c3b30a4c54e133da919eed069622e708c7e65e2975d53dce6b9716e701a1efb41664a6c94790a3f344ff4d539f3d8eef24be95746704cc3cdaa21308770a5a84f3c44608a60311dd4eaeed68c34d6dfd6d3b445c0173ee19cb857893267070dcb0a2f3de48c2f6f9d8a93c81866c191cc20031f0503c6b9690d160ab7fe81864f4d61804b95fe6fa14e88df5cd29c2f36daef51bfe9c64ce7dd58503fd16a8f4b70a2f5805828cba5c4ecb5a8862271838d6b087e98326e3e54e6e3d9f7653da668e520487acc8638e5202bd60625c73a2effede1314bb1a0c5cf827d7e732d36ec716990b05e3e5f029a8ad17b8e02d317d1e616a51ebc42db61a78b410c61719f4e1216f445c40cffe448b445862e33acd62a5c59ee5a6d748f943deed9fac7b86ff006c4be25ec18aa042c1bba440f0d66776cf6e44a523cd8044f63f286db5062900146b94cb3592f5ba070039654e840b4d6d4096804a9dec84eb2aedf1ccd916dcd817ab2c03a1e59f9596fcea6d27d7943ae21bedfb79067afd8aa9c00214a87f60dbb45033de7de23965641a10363129bc691c435f978777524d1de5fe573a26e617b9c906607946bcaf6296d2b3660dd5dbccf2a14b87515f259dd2d92c8c4467fc605ff2bb565c3ec83da64062c1ec9d6c4c5992e5cec438a13fc1f88bf25cd14f0bf76d140bbcc2a5489921f68b9ad4b8b86589520e75dec9bd08635d500d70bde710aa77ca974335eb278e766ff0a9c748830b70f530393ddf161c47861acbace3788de8a49bfc5cc311aba120094fcb631bfe97ea1e56aa5f43948cc399048617397bbde2a4af9930758a2e7762bef2d0dad7bfe830b17b5ed86e05d818401cc105dd7e9035a7af9a2741a056a5d083bf75caa55ec9eb42f998e66db4f3cd663605ce05f64961e86bb2925b71091c4d69d0bcba893f94229f5b323d5a51351700d048bba6dfc5244fd945e092cbbf822d86d3c30a9da43f408f140fc52c66e5bea0c8e877f1dd53c06037f57758bdbd2d80963dc3a2ef5cd656c982b83c13facd1e33e036ab4b45b1311bddbc7a087bdccad93e255ef2d7dfd62ddace20f66c186df52332f2d337685683bd66633a9dd25e1b31bb7f26243761423213d8d7f7ab9020c5f5258cc1455a8d4f9279d5e09249f50bfcd99427258348fb8fa3edfcb984c8aca55b1cdd434485e6dbfe19b33a623e19b26d857a684b0ebc90b48c5cf5459adf1ba22460ece4bde68a2e9ea240ce33bae90ff8ec3b05af89dda38d2664e19209c17111126b90b8d7908a6afbf4c8f815127bf7bce900a1835fa807926d63877320a44eea61f34b15dc13236cf4fffc7f41dba551b3c6f8fe8cdb46d9d71dd30cc93784ea8e12440bcd593f2ab1b5e934b68372967c1a8729d7db016c3df3592baf37c650af784793e44814c26b222127a68c851642add1a8f460921a1872374a0f9eab7449063f17164d9f35442fce2491f363c701769f3dbede91a53dd1c65729d1cae9adef8ffcb437776ee2c4e6fb1dfe6f25af61400ea6120bff738020769c1e9cb2d32fee1e0c2c295faa66b7f31ed3c7ce2f048ca728d8efdc46e2c7c866e72aadf93dfe9e480856a4b9ab2e6776f3bd82e5331cc70bbd2bcadc96827acf8f0d56eaeeabf892b17e05230d93e4ad11a4a94ebf466e319035bb589ad117ec107b6725a894cd01cc2dc0dcec4d3952953d8197fd7963790a8f2b38cd3036f62e33946a4b1b6b5578b5fe28c106df7c371812845d958b438ff48e15971150df71ccbcebc982626affca8c6252240e51e586bb318b182805a03ad7cb85e75b88fbce8907ec77149b92d1f4134178ff8f40defaf341e4dff49582d7b02d0fc99e1822de28f317b0095ee9ad8d2ede98e74292e21345ce51c1eb34312f4e0ce3307d7e73ba1b2d5202045fa3cf386f052f18908c319f2e45908344c4fe8d32cb6d2f576d37b4e9e6d0042a5321b59fbea9ec26466a9e434c66f7f47b3a03f226576557c2d9dd339ec2249350a1579df90e29c067b47672860f44b18fc43e0a2d612d332a8b0c90f7aeb3c1f82ef56d3014dd14dab35ff6e3d57133929a39c7c060684c9b714ef481d6cc1e2e5c03f3a5a9a2565b56fbabc87aa05c8c3b8bc1a4e3ae809288e52df927e54ac2809f7424dc039d38287215f416b818d1fa663d3ce492f2be614bb525b4d55d5fc18194458e2c478b6c7fea68e9237fc724ad93da8a987bbe7fcacf0ed442ebfe33d6d0dfd5a548ddeb79de39c952ce3e9827f937fb1b39363914592c85a108ae13c587d1f7659027922d6d3988055bdf9848abffb38f970520b7b91f22de984d561e73f378153892524abfead38857937e1528321b2b0653068b721f37ec5b99f2c1a8f2d07119245ddd18bfb6d4a4b2067b765dae434918b480b57d9012fabf3e71f465cc8853f3adced7aa1b8156995ecc479e284f7baf5e44d2bcc83155df7ddef5d231b9d0b24bb6b88449396b4e1395ef93a7c5350c1243f31e2426470c4c675a4f9542010e3ba4633f59d0d686e28dabc2e6a552d17b185b2ad9ee8c04754762f227a81cc5ec8753cac43b7a35b2a8a89b7c0706193a5a9833bd756339dfba2f3a8d1abbe5ff254348eed1bc5b36d6ea1a49afc56540849d7e10f58cf0776f0e0b0b3bfc06a4bd7ee94ccf05c66d3e6ee7143f44e44d18c006ed5ff52095039e873962eefbfa4eaab0e1a5815f7281eaf676ff3a13fa619de85fd92b9825caa6cac785bfee473562b74b5bdccea6879a90c6c2e45186dd61e188aa921be07f29afae8f4a8ad718b8109234839ce318ba1d7c5bd4000c9851882844bf46c157d18c0df498eea48868afbafebec565c98273a14028806e0871940dfa94058fb531b0cbf06701cf1f6f42014ad42d177be0add510ccf52df7789ed0343640cd8c9d0952ded2b6f69ae2ef80f1617c8af9fba3cbabff96077ae9793cdb09ce63bbe3817294cab50470cd0965217e7703601c7516bc7290dcfd2f0b0a17aa80d5d8c4bcd3147b4efb5c729c676a87f37ef02ce680dd4946683798356d8c7120832e09319435443c2f325acb684a98807d4258876fcd4fd7dc1f30eae1dfd34f2a3d7c94f2eb9430e23372edf84fda3f157ddf3b8cd81458cbb0b115980f7a656d204f93c5"}', headers
    expect(last_response.status).to eq(406)

    parsed_response = JSON.parse(last_response.body)
    expect(parsed_response.size).to eq(1)
    expect(parsed_response['error']).to eq('Content-Length invalid')
  end  

  it "creates a Route called world" do
    headers = { "CONTENT_TYPE" => "application/json" }
    post "/addme", '{ "path": "/world", "response": "hello"}', headers
    expect(last_response).to be_ok

    parsed_response = JSON.parse(last_response.body)
    expect(parsed_response.size).to eq(3)
    expect(parsed_response['path']).to eq('/world')
    expect(parsed_response['response']).to eq('hello')
  end

  it "says Route limit reach for IP address" do
    headers = { "CONTENT_TYPE" => "application/json" }
    post "/addme", '{ "path": "/hello2", "response": "world"}', headers

    parsed_response = JSON.parse(last_response.body)
    expect(parsed_response.size).to eq(1)
    expect(parsed_response['error']).to eq('Route limit reach for IP address')
  end

end
