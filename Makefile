.PHONY: dev build clean

dev:
	hugo server -D --navigateToChanged --disableFastRender

build:
	hugo --minify

clean:
	rm -rf public/ resources/
