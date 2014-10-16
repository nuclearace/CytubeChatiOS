//
//  CytubeUtils.swift
//  CytubeChat1.0
//
//  Created by Erik Little on 10/15/14.
//

import Foundation

class CytubeUtils {
    
    class func filterChatMsg(data:String) -> String {
        var mut = RegexMutable(data)
        mut = mut["(&#39;)"] ~= "'"
        mut = mut["(&amp;)"] ~= "&"
        mut = mut["(&lt;)"] ~= "<"
        mut = mut["(&gt;)"] ~= ">"
        mut = mut["(&quot;)"] ~= "\""
        mut = mut["(&#40;)"] ~= "("
        mut = mut["(&#41;)"] ~= ")"
        var link = mut["src=\"(.*?)\""].matches()
        mut = mut["(<([^>]+)>)"] ~= ""
        mut = mut["(^[ \t]+)"] ~= ""
        
        println(link)
        return mut as NSString
    }
}