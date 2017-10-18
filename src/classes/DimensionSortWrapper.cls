global class DimensionSortWrapper implements Comparable {

  private AxSFD__Dimension__c theDimension;

  public static Map<String, Integer> dictionary;

  public DimensionSortWrapper(AxSFD__Dimension__c dim) {
    theDimension = dim;
    if (DimensionSortWrapper.dictionary == NULL || DimensionSortWrapper.dictionary.size() == 0) {
      DimensionSortWrapper.dictionary = defineDictionary();
    }
  }

  global Integer compareTo(Object compareTo) {
    DimensionSortWrapper dimensionToCompare = (DimensionSortWrapper) compareTo;
    Integer original = dictionary.get(theDimension.AxSFD__AccountHealthScoringModel__r.AxSFD__DimensionType__c);
    Integer comparing = dictionary.get(dimensionToCompare.getDimension().AxSFD__AccountHealthScoringModel__r.AxSFD__DimensionType__c);
    if (original == comparing) {
      return 0;
    }
    if (original > comparing) {
      return 1;
    }
    return -1;
  }

  private static Map<String, Integer> defineDictionary() {
    Map<String, Integer> orderedTypes = new Map<String, Integer>();
    Schema.DescribeFieldResult fieldResult = AxSFD__AccountHealthScoringModel__c.AxSFD__DimensionType__c.getDescribe();
    List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
    Integer orderNumber = 1;
    for( Schema.PicklistEntry theType : ple) {
      orderedTypes.put(theType.getValue(), orderNumber++);
    }
    return orderedTypes;
  }

  public AxSFD__Dimension__c getDimension() {
    return theDimension;
  }

  private static List<String> getSortedDictionaryKeyset(Map<String, Integer> unsorted) {
    List<String> sorted = new List<String>();
    Map<Integer, String> reverse = new Map<Integer, String>();
    for (String s : unsorted.keySet()) {
      reverse.put(unsorted.get(s), s);
    }
    List<Integer> toSort = new List<Integer>(reverse.keySet());
    toSort.sort();
    for (Integer key : toSort) {
      sorted.add(reverse.get(key));
    }
    return sorted;
  }

  public static List<String> getSortedDatamapKeyset(Map<String, Object> unsorted) {
    System.debug(unsorted);
    List<String> result = new List<String>();
    if (dictionary == NULL || dictionary.size() == 0) {
      dictionary = defineDictionary();
    }
    System.debug('DICT: ' + dictionary);

    for (String key : getSortedDictionaryKeyset(dictionary)) {
      System.debug(key);
      if (unsorted.get(key) != NULL) {
        result.add(key);
      }
    }
    return result;
  }

  public static List<String> getSortedDictionaryKeyset() {
    return getSortedDictionaryKeyset(dictionary);
  }
}