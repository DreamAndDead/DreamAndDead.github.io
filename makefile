serve:
	hugo server

dev:
	hugo -b http://localhost:8000
	(cd public; python -m http.server; cd ..)

prod:
	hugo
