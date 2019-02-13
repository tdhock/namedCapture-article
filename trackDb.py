import sys
trackDb_path = sys.argv[1]
trackDb = open(trackDb_path).read()
pattern = "track ([A-Za-z0-9_]+)"
modules = ("re2", "re", "pcre")
import cProfile
def get_list(module_name):
    mod = __import__(module_name)
    pat = mod.compile(pattern)
    return [m.group(1) for m in pat.finditer(trackDb)]
    
for module_name in modules:
    code = "get_list('%s')" % module_name
    print code
    print cProfile.run(code)

