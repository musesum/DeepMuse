//  Created by warren on 12/29/19.

import Foundation

extension MetNode {

    @discardableResult
    public func insert(before: MetNode?) -> MetNode? {
        if let before = before {
            inNode = before.inNode
            outNode = before
            before.inNode = self
        }
        return self
    }
    
    @discardableResult
    public func insert(after: MetNode?) -> MetNode {
        if let after = after {
            inNode = after
            // avoid creating a loop if already inserted before
            if after.outNode != self {
                outNode = after.outNode
                after.outNode = self
            }
        }
        return self
    }
    public enum InsertWhere { case above, below }

    @discardableResult
    public func insertNode(_ insertNode: MetNode,
                           _ insertWhere: InsertWhere) -> MetNode? {

        if insertNode.id == self.id { return self }

        switch insertWhere {

            case .above:
                // already inserted above?
                if insertNode.outNode == self { return self}

                insertNode.inNode = inNode
                insertNode.outNode = self
                insertNode.inTex = inTex
                insertNode.outTex = makeNewTex("insertNode.above")

                inNode?.outNode = insertNode
                inNode = insertNode
                inTex = insertNode.outTex

            case .below:
                // already inserted below?
                if insertNode.inNode == self { return self }

                insertNode.inNode = self
                insertNode.outNode = outNode
                insertNode.inTex = outTex
                insertNode.outTex = makeNewTex("insertNode.below")

                outNode?.inNode = insertNode
                outNode?.inTex = insertNode.outTex
                outNode = insertNode
        }
        return self
    }

    public func replace(with newNode: MetNode?) -> MetNode? {

        if let n = newNode {

            n.inTex = inTex
            n.outTex = outTex
            n.altTex = altTex
            n.outNode = outNode
            n.inNode = inNode
            n.metItem.size = metItem.size

            if  inNode?.outNode?.id == id {
                inNode?.outNode = newNode
            }
            if  outNode?.inNode?.id == id {
                outNode?.inNode = newNode
            }
            return n
        }
        return self
    }


}
