from typing import List, Tuple
from cspy.db.datastore import CspDataStore
import sys
import matplotlib.pyplot as plt
import logging
import os
import datetime

now = datetime.datetime.now()

logfile=f"compare_order_structs_{str(now.strftime('%d-%m-%y_%H:%M:%S'))}.log"
LOG = logging.getLogger(__name__)
logging.basicConfig(filename=logfile,
                    level=logging.INFO, datefmt="%H:%M:%S",
                    format="%(levelname)s:%(filename)s:line %(lineno)d:time %(asctime)s:  %(message)s")
print(f"Writing to log file: {logfile}")

# fetch data from first database
if not os.path.exists(sys.argv[1]):
    LOG.error(f"Could not load database with name: {sys.argv[1]}")
    sys.exit(1)

try:
    db1 = CspDataStore(sys.argv[1])
    LOG.info(f"Loaded database: {sys.argv[1]}")
except Exception as e:
    LOG.error(f"Could not load database with name: {sys.argv[1]}", exc_info=1)
    sys.exit(1)

data1: List[Tuple[str, float]] = [item for item in db1.query("select id, energy from crystal where id like '%-3'").fetchall()]
data1.sort(key=lambda a: a[1])
LOG.info(f"Read {len(data1)} structures from database")

# fetch data from second database
if not os.path.exists(sys.argv[2]):
    LOG.error(f"Could not load database with name: {sys.argv[2]}")
    sys.exit(1)

try:
    db2 = CspDataStore(sys.argv[2])
    LOG.info(f"Loaded database: {sys.argv[2]}")
except Exception as e:
    LOG.error(f"Could not load database with name: {sys.argv[2]}", exc_info=1)
    sys.exit(1)

data2: List[Tuple[str, float]] = [item for item in db2.query("select id, energy from crystal where id like '%-3'").fetchall()]
data2.sort(key=lambda a: a[1])
LOG.info(f"Read {len(data2)} structures from database")

# output file name
if len(sys.argv) >= 4:
    outfile=sys.argv[3]
else:
    outfile="order_change.csv"
LOG.info(f"csv data will be saved to file: {outfile}")

pos_pairs: List[Tuple[int, int]] = []
energy_pairs: List[Tuple[float, float]] = []
with open(outfile, mode="w") as out:
    LOG.info(f"{outfile} opened for writing")
    out.write("ID,POS1,ENERGY1,POS2,ENERGY2\n")
    for i, crystal1 in enumerate(data1):
        id1 = crystal1[0].replace("-OPT-3", "")
        energy1 = crystal1[1]

        for j, crystal2 in enumerate(data2):
            id2 = crystal2[0].replace("-OPT-3", "")
            energy2 = crystal2[1]

            if id1 == id2:
                out.write(f"{id1},{i},{energy1},{j},{energy2}\n")
                pos_pairs.append((i, j))
                energy_pairs.append((energy1, energy2))
                break
        else:
            LOG.warning(f"There is no matching structure in database 2 with id similar to: {id1}")
LOG.info(f"Finished writing to {outfile}")

# create plots
for pos1, pos2 in pos_pairs:
    if pos2 > 200: continue # plot the 200 first ranked structures
    plt.plot([0, 1], [pos1, pos2], 'o-')
plt.xticks([0, 1], [sys.argv[1], sys.argv[2]])
plt.ylabel('Ranking')
plt.tight_layout()
plt.show()
plt.savefig('ranking_pos.png', dpi=600)
LOG.info("Saved figure Ranking_pos.png")