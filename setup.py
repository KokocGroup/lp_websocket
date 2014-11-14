from setuptools import setup, find_packages

setup(
    name='ws-notify',
    version='1.0',
    description='Notification server',
    long_description=open('README.rst').read(),
    author="GoTLiuM InSPiRiT",
    author_email='gotlium@gmail.com',
    url='https://github.com/LPgenerator/lpg-notify-ws/',
    packages=find_packages(exclude=['demo']),
    include_package_data=True,
    package_data={'secureauth': [
        'templates/*.html',
        'static/*.js'
    ]},
    zip_safe=False,
    classifiers=[
        'Development Status :: 5 - Production/Stable',
        'Programming Language :: Python',
    ],
    install_requires=[
        'tornado>=4.0.2',
        'tornado-redis>=2.4.18',
        'raven>=5.1.1',
    ]
)
