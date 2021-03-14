serve:
	hugo server -D

prod:
	hugo -b http://localhost:8000
	(cd public; python -m http.server; cd ..)

