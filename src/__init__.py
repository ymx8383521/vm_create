from config import settings
import os
if not os.path.exists(settings.ISO_NONE_LOCAL):
    f=open(settings.ISO_NONE_LOCAL, 'w')
    f.close()