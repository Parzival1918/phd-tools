from cspy.db.datastore import CspDataStore
import sys


# fetch data from first database
db1 = CspDataStore(sys.argv[1])
data1 = [item for item in db1.query("select id, energy from crystal order by energy asc where id like '%-3'").fetchall()]

# fetch data from second database
db2 = CspDataStore(sys.argv[2])
data2 = [item for item in db2.query("select id, energy from crystal order by energy asc where id like '%-3'").fetchall()]