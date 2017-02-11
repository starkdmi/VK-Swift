
import PlaygroundSupport
import UIKit
import WebKit
import Foundation

extension String {
    func indexOf(target: String) -> Int {
        var range = self.range(of: target)
        if let range = range {
            return distance(from: self.startIndex, to: range.lowerBound)
        } 
        else
        {
            return -1
        }
    }
}

extension String.Index{
    func advance(_ offset:Int, for string:String)->String.Index{
        return string.index(self, offsetBy: offset)
    }
}

extension UIImage {
    var circle: UIImage? {
        let square = CGSize(width: min(size.width, size.height), height: min(size.width, size.height))
        let imageView = UIImageView(frame: CGRect(origin: .zero, size: square))
        imageView.contentMode = .scaleAspectFill
        imageView.image = self
        imageView.layer.cornerRadius = square.width/2
        imageView.layer.masksToBounds = true
        UIGraphicsBeginImageContextWithOptions(imageView.bounds.size, false, scale)
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        imageView.layer.render(in: context)
        let result = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return result
    }
}

extension Dictionary { 
    subscript(i:Int) -> (key:Key,value:Value) { 
        get { 
            return self[i] 
        } 
    } 
}

var VK_Access_Token: String? = nil
var VK_Client_Id: String = "4939758"
typealias VK_Dictionary = Dictionary<String,AnyObject>

struct User { 
    //var Id: String?
    var Name: String?
    var Photo: String?
}

func GetReguest(_ str:String) -> String {
    let url = URL(string: str)
    do {
            let contents = try NSString(contentsOf: url!, usedEncoding: nil)
            return contents as String
    } catch {
        // Ошибка
        return NSError.description()
    }
}

func ParseJsonData(_ str: String) -> VK_Dictionary
{
    var data = str.data(using: .utf8)!
    
    let jsonObject: AnyObject! = try? JSONSerialization.jsonObject(with: data) as AnyObject!
    
    let response = (jsonObject as! VK_Dictionary)["response"] as! VK_Dictionary
    
    return response
}

func ParseJsonFriendsData(_ str: String) -> [User]
{
    var data = str.data(using: .utf8)!
    
    let jsonObject: AnyObject! = try? JSONSerialization.jsonObject(with: data) as AnyObject!
    
    let response = (jsonObject as! VK_Dictionary)["response"] as! NSArray
    
    var Users = [User]()
    
    for i in 0 ... response.count - 1 {
        var user = User()
        let json_user = response[i] as! VK_Dictionary
        //user.Id = json_user["id"] as! String
        user.Name = json_user["name"] as! String
        user.Photo = json_user["photo"] as! String
        
        Users.append(user)
    }
    
    return Users
}

class AuthController: UIViewController, UIWebViewDelegate, WKUIDelegate, WKNavigationDelegate{  
    @IBOutlet var containerView : UIView? = nil  
    var webView: WKWebView?  
    
    override func loadView(){  
        super.loadView()  
        webView = WKWebView()  
        self.view = webView
    }  
    
    override func viewDidLoad(){  
        super.viewDidLoad()  
        
        // UserDefaults.standard.removeObject(forKey: "VK_Access_Token")
        
        if let token = UserDefaults.standard.string(forKey: "VK_Access_Token")
        {
            webView?.isHidden = true
            
            VK_Access_Token = token
            
            let mainPage = MainController()
            PlaygroundPage.current.liveView = UINavigationController(rootViewController: mainPage)
            PlaygroundPage.current.needsIndefiniteExecution = true
        }
        else
        {
            var url = URL(string:"https://oauth.vk.com/authorize?client_id=\(VK_Client_Id)&redirect_uri=https://oauth.vk.com/blank.html&scope=offline&display=touch&v=5.33&response_type=token")  
            
            //url?.removeAllCachedResourceValues()
        
        var req = URLRequest(url:url!)  
        webView!.addObserver(self, forKeyPath: "estimatedProgress", options: .new, context: nil)
            webView!.load(req)  
        }
    }  
    
    override func observeValue(forKeyPath keyPath: String?, of object: AnyObject?, change: [NSKeyValueChangeKey : AnyObject]?, context: UnsafeMutablePointer<Void>?) {
        if keyPath == "estimatedProgress" {
            if webView?.estimatedProgress == 1.0
            {
                if ((webView?.url?.absoluteURL.absoluteString.range(of: "access_token")) != nil) &&  webView?.url?.host == "oauth.vk.com" {
                    webView?.isHidden = true
                    
                    let parameters = webView?.url?.absoluteURL.absoluteString.components(separatedBy: "#")[1]
                    
                    let parameters_token = parameters?.components(separatedBy: "&")[0]
                    
                    VK_Access_Token = parameters?.substring(with: (parameters_token?.characters.startIndex.advance(13, for: parameters_token!))!..<(parameters_token?.characters.endIndex)!)
                    
                    UserDefaults.standard.set(VK_Access_Token, forKey: "VK_Access_Token")
                    
                    webView?.removeObserver(self, forKeyPath: "estimatedProgress")
                    
                    let mainPage = MainController()
                    PlaygroundPage.current.liveView = UINavigationController(rootViewController: mainPage)
                    PlaygroundPage.current.needsIndefiniteExecution = true
                }
            }
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}

class MainController: UIViewController{
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "VK"
        
        var content = GetReguest("https://api.vk.com/method/execute.short_user_info?v=5.50&access_token=" + VK_Access_Token!)
        
        let info = ParseJsonData(content)
        
        view.sizeToFit()
        view.backgroundColor = #colorLiteral(red: 0.176470592617989, green: 0.498039215803146, blue: 0.756862759590149, alpha: 1.0)
        
        // let height = view.frame.size.height
        // let width = view.frame.size.width
        
        let imageView = UIImageView(frame: CGRect(x: 30, y: 70, width: 100, height: 100))
        
        let profileImage = UIImage(data: try! Data(contentsOf: URL(string: info["photo_max"] as! String)!))!
        
        imageView.image = profileImage.circle
        
        let nameLabel = UILabel(frame: CGRect(x: 140, y: 80, width: 200, height: 100))
        nameLabel.text = (info["last_name"] as! String) + " " + (info["first_name"] as! String)
        nameLabel.textColor = #colorLiteral(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)
        nameLabel.sizeToFit()
        
        let cityLabel = UILabel(frame: CGRect(x: 140, y: 110, width: 200, height: 100))
        cityLabel.text = (info["city"] as! String)
        cityLabel.textColor = #colorLiteral(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)
        cityLabel.sizeToFit()
        
        content = GetReguest("https://api.vk.com/method/execute.friends_get_top?v=5.50&access_token=" + VK_Access_Token!)
        
        let friends = ParseJsonFriendsData(content)
        
        view.addSubview(imageView)
        view.addSubview(nameLabel)
        view.addSubview(cityLabel)
    }
}

let AuthPage = AuthController()
PlaygroundPage.current.liveView = AuthPage
PlaygroundPage.current.needsIndefiniteExecution = true
