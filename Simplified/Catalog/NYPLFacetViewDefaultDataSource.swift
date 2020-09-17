@objcMembers final class NYPLFacetViewDefaultDataSource: NSObject, NYPLFacetViewDataSource {

  let facetGroups: [NYPLCatalogFacetGroup]

  required init(facetGroups: [NYPLCatalogFacetGroup]) {
    self.facetGroups = facetGroups
  }

  //MARK: -

  func numberOfFacetGroups(in facetView: NYPLFacetView!) -> UInt {
    return UInt(facetGroups.count)
  }

  func facetView(_ facetView: NYPLFacetView!, numberOfFacetsInFacetGroupAt index: UInt) -> UInt {
    return UInt(self.facetGroups[Int(index)].facets.count)
  }

  func facetView(_ facetView: NYPLFacetView!, nameForFacetGroupAt index: UInt) -> String! {
    return self.facetGroups[Int(index)].name
  }

  func facetView(_ facetView: NYPLFacetView!, nameForFacetAt indexPath: IndexPath!) -> String! {
    let group = self.facetGroups[indexPath.section]
    let facet = group.facets[indexPath.row] as! NYPLCatalogFacet
    return facet.title
  }

  func facetView(_ facetView: NYPLFacetView!, isActiveFacetForFacetGroupAt index: UInt) -> Bool {
    let group = self.facetGroups[Int(index)]
    for facet in group.facets as! [NYPLCatalogFacet] {
      if facet.active {
        return true
      }
    }
    return false
  }

  func facetView(_ facetView: NYPLFacetView!, activeFacetIndexForFacetGroupAt index: UInt) -> UInt {
    let group = self.facetGroups[Int(index)]
    var index: UInt = 0
    for facet in group.facets as! [NYPLCatalogFacet] {
      if facet.active {
        return index
      }
      index += 1
    }
    fatalError("InternalInconsistencyException")
  }
}
