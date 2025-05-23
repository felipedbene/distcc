# **Reviving the iBook G4: A 20-Year Dream Meets Modern Challenges**  

## **Introduction**  
When I was a teenager, I dreamed of owning an iBook G4. Back then, its PowerPC CPU with AltiVec extensions sounded like the most powerful processor in the world—capable of incredible multimedia performance. Fast forward 20 years, and I finally got my hands on one. But as with many vintage machines, 80 bucks on ebay and it came clean, all manuals, box. piece of art. the real challenge begins *after* the purchase: making it usable in today’s world.  

You have to run linux on it and this is certainly my persaonal journey diary, i will do it slowly just to make i don't lose any geekness.

## **The HTTPS Problem: A Brick Wall for Browsers**  
The first major hurdle? **The internet.** Modern HTTPS and SSL/TLS standards have evolved, leaving older systems like the G4 unable to establish secure connections. Most browsers (even lightweight ones like TenFourFox) struggle because the iBook can’t negotiate modern encryption. Without a working browser, the machine feels crippled—so I had to find another way.  

## **Trial and Error: Linux to the Rescue (Sort Of)**  
I experimented with various lightweight Linux distributions:  
- **Void Linux (PPC)** – Fast, but limited software support,    THIS NEVER EVEN BOOT.
- **Debian (PPC)** – Stable, but bloated for the G4’s hardware, PAINFULLY SLOW
- **Mac OS Sorbet Leopard** – A polished retro macOS experience, but still limited in functionality.  SAME SHIT BUT A LITTLE MODERN CERT CHAIN.


While these options worked, none felt *optimal*. That’s when I turned to **Gentoo**.  

- This gent https://tinkerdifferent.com/threads/cracking-the-code-gentoo-linux-on-an-ibook-g4-success-story.3339/ HAS DONE AN ABSOLUTELY A VERY THROURGH DOCUMENTATION AND SOME OF THE STUFF HE MADE WORK, STILL THE BEST OUT THERE.

## **Gentoo: The Power of Custom Optimization**  
Gentoo is unique—it compiles everything from source, tailored to your exact hardware. For an aging PowerPC machine, this means squeezing out every drop of performance. Most software runs surprisingly well when optimized for the G4’s architecture. < do some altivec explanation, go deep> and then compare with modern tech, like m1 macs.

But there’s a catch: **compiling takes forever.** A full Linux kernel build? **Up to three days.** That’s when I decided to build a **distributed compilation farm**.  

## **DistCC: Supercharging Compilation with a Cluster**  
I set up **distcc**, a tool that distributes compilation tasks across multiple machines. My setup:  
- A **manifest file** defining the build environment.  
- Tweaked **compiler flags** for PowerPC compatibility.  
- **Grafana dashboards** to monitor compilation progress in real-time.  
<- This cluster is a such diverse cluster that it deserves an article on its own.> a sneak peak :

"➜  ~ kubectl get nodes -o wide
NAME        STATUS     ROLES           AGE   VERSION   INTERNAL-IP   EXTERNAL-IP   OS-IMAGE                         KERNEL-VERSION         CONTAINER-RUNTIME
pi1         Ready      <none>          50d   v1.32.3   10.0.10.101   <none>        Ubuntu 24.10                     6.11.0-1012-raspi      containerd://2.0.4
pi2         Ready      <none>          50d   v1.32.3   10.0.10.102   <none>        Ubuntu 24.10                     6.11.0-1012-raspi      containerd://2.0.4
pi3         Ready      <none>          50d   v1.32.3   10.0.10.103   <none>        Ubuntu 24.10                     6.11.0-1012-raspi      containerd://2.0.4
pi4-o       NotReady   <none>          20h   v1.32.3   10.0.10.104   <none>        Unknown                          6.1.99-vendor-rk35xx   containerd://2.0.4
pi5-intel   Ready      <none>          50d   v1.32.3   10.0.10.105   <none>        Ubuntu 24.04.2 LTS               6.8.0-60-generic       containerd://2.0.4
zpimaster   Ready      control-plane   50d   v1.32.3   10.0.10.100   <none>        Debian GNU/Linux 12 (bookworm)   6.1.0-34-amd64         containerd://2.0.4
➜  ~




" 
pleas expand on it.

The result? **A kernel that once took days now compiles in hours—or even minutes.**   any stat you can add here?

Check out my **[distcc setup guide on GitHub](https://github.com/felipedbene/distcc)** if you want to try it yourself!  

## **Conclusion: The iBook G4 Shines Again**  
Now, my G4 isn’t just a nostalgic relic—it’s a functional machine capable of running modern(ish) software. The journey wasn’t easy, but the payoff was worth it.  

**Next up?** A deeper dive into optimizing specific applications, benchmarking performance gains, and maybe even overclocking this old beast.  

Stay tuned!