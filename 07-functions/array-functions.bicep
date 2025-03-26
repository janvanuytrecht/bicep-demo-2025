// array-functions.bicep
// Demonstrates array manipulation functions in Bicep

// Input parameters
@description('Array of Azure regions to consider for deployment')
param regions array = [
  'eastus'
  'westus'
  'northeurope'
  'westeurope'
  'southeastasia'
]

@description('Array of allowed VM sizes')
param allowedVmSizes array = [
  'Standard_D2s_v3'
  'Standard_D4s_v3'
  'Standard_D8s_v3'
  'Standard_E2s_v3'
  'Standard_E4s_v3'
]

@description('Environment type (dev, test, prod)')
@allowed([
  'dev'
  'test'
  'prod'
])
param environment string = 'dev'

// Array function examples
var arrayExamples = {
  // Get the first item in an array
  firstRegion: first(regions)  // Returns 'eastus'

  // Get the last item in an array
  lastRegion: last(regions)  // Returns 'southeastasia'

  // Get array length
  regionCount: length(regions)  // Returns 5

  // Slice an array (get a subset)
  europeRegions: slice(regions, 2, 2)  // Returns ['northeurope', 'westeurope']

  // Create a range of sequential numbers
  rangeExample: range(1, 5)  // Returns [1, 2, 3, 4, 5]

  // Check if array contains a value
  hasWestUs: contains(regions, 'westus')  // Returns true

  // Join array elements into a string
  regionsString: join(regions, ', ')  // Returns 'eastus, westus, northeurope, westeurope, southeastasia'

  // Array union (combine arrays without duplicates)
  combinedArr: union(['a', 'b', 'c'], ['b', 'c', 'd'])  // Returns ['a', 'b', 'c', 'd']

  // Array intersection (only items in both arrays)
  commonElements: intersection(['a', 'b', 'c'], ['b', 'c', 'd'])  // Returns ['b', 'c']

  // Filter array based on a condition
  usRegions: filter(regions, region => contains(region, 'us'))  // Returns ['eastus', 'westus']

  // Transform each item in an array
  uppercaseRegions: map(regions, region => toUpper(region))

  // Sort array in ascending order
  sortedRegions: sort(regions)
}

// Using arrays for real deployments
// Determine deployment regions based on environment
var deploymentRegions = environment == 'prod' ? regions : filter(regions, region => contains(region, 'us'))

// Determine VM sizes based on environment
var vmSizes = environment == 'prod' ?
              filter(allowedVmSizes, size => contains(size, 'D8') || contains(size, 'E4')) :
              filter(allowedVmSizes, size => contains(size, 'D2') || contains(size, 'D4'))

// Practical example: deploy storage accounts to selected regions
module storageAccounts 'storage-module.bicep' = [for region in deploymentRegions: {
  name: 'storage-${region}-deployment'
  params: {
    location: region
    storageAccountName: 'st${take(uniqueString(resourceGroup().id, region), 12)}'
    environment: environment
  }
}]

// Outputs to review array function results
output arrayExamples object = arrayExamples
output deployTo array = deploymentRegions
output selectedVmSizes array = vmSizes
