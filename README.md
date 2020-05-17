# StringUntagger

![Swift](https://github.com/nacho4d/StringUntagger/workflows/Swift/badge.svg)

A simple class to convert tagged strings to attributed strings. This is specially useful when strings are attributed and localized.

Simplest example:

    let res = "click <i>here</i> please".attributted(attributter: [
        "root": [ .foregroundColor: UIColor.gray, .font: UIFont.systemFont(ofSize: 17)],
        "i": [ .font: UIFont.boldSystemFont(ofSize: 17) ]
    ])
    
Root tag name can be customized too

    let su = StringUntagger(rootName: "MyCustomRootName")
    let res = su.attributedString(from: "start <root>this is the middle</root> end", attributer: [
        "MyCustomRootName": [ .foregroundColor: UIColor.lightGray, .font: UIFont.systemFont(ofSize: 12)],
        "root": [ .foregroundColor: UIColor.blue],
    ])
    
There is also a block base API that should give full control. Check the tests to find out more :)

MIT Licence

