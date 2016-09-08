/* Sigma.lua
 *
 * Compute sum = 1 + 2 + ... + n
 */

// variables
const integer n = 1000
integer sum = 300
integer index = 0
print 0 - 1000
while (index < n) do
 sum = sum * n
 sum = sum + index
 index = index + 1
 print "index "
 println index
 print "The sum is "
 println sum
end
sum = sum + 1
print "The sum is "
println sum
