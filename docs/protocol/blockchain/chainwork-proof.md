# Chainwork Proof

The idea of chainwork is intrinsic to blockchains.  Nodes switch to the chain tip with the most cumulative "work" to help preserve the blockchain assumption that the majority of the miners on a chain are honest.  Chainwork is calculated by summing the "work" done in each block in the chain.  

Is summing work a valid operation?

More formally, *is the expected number of hashes to solve one block candidate with work W is equal to the expected number of hashes to solve N block candidates with work W/N?*

## Warm-up

For every block candidate, a target (specified in a nonstandard floating point form in the block header as 'nBits') is calculated.  Any hash less than this target solves the block.  Under the random oracle model (that is, assuming that cryptographic hash functions produce unpredictable output), this is equivalent to rolling a $2^{256}$ sided die with any number less than or equal to the target resulting in a "win".  The probability of this is:

$$
P(target) = (target + 1)/2^{256}       \tag1
$$

*We add one to target because the number range of target is from 0 to $2^{256}-1$, rather than 1 to $2^{256}$.*

Equation 1 is about the target, but we sum work.   We need the relationship between work and target which is defined in the code as follows:

$$
work = 2^{256}/ (target + 1)
$$

or, solving for target:

$$
T(work) = (2^{256}/work) -1   \tag2
$$

Finally we need an equation from general statistics.  The expected number of trials before a success for such a random variable is given by (see [wikipedia](https://en.wikipedia.org/wiki/Geometric_distribution#Properties)):

$$
E(probability\_of\_success) = 1/probability\_of\_success    \tag3
$$

'Trials' in our case are individual attempts to solve a block.  So if the expected number of trials of two different processes are the same then we can say those two processes would take the same amount of work (on average).

## Proof

Recall our question "*is the expected number of hashes to solve one block candidate with work W is equal to the expected number of hashes to solve N block candidates with work W/N?*"

With the above definitions this can be expressed in mathematical notation:

$$
E(P(T(work))) \stackrel{?}{=} n * E(P(T(work/n)))    \tag4
$$

With all of our preparation, this proof is easy.  But I'll go through each step to make it convenient to read along.  

First we'll replace the functions with their defintions on the left side **to prove that what the blockchain community calls "work" is the expected number of hashes**.

$$
E(P(T(work))) = E(P((2^{256}/work) -1))
$$

$$
 = E(((2^{256}/work) -1 + 1)/2^{256})
$$

$$
 = E((2^{256}/work)/2^{256})
$$

$$
 = E(1/work)
$$

$$  
 = work
$$


Second we'll do the same on the right side and simplify to prove that the result is the same:

First, substitute the definition of T() (eqn 2):

$$  
n * E(P(T(work/n))) = n * E(P((n*2^{256}/work) -1)
$$

Next, substitute the definition of P() (eqn 1):

$$
 = n * E( ((n*2^{256}/work))/2^{256})
$$

Third, substitute the defintion of E() (eqn 3):

$$
= \dfrac{n}{\frac{(n*2^{256}/work )}{2^{256}}}
$$

Finally, simplify:

$$
= \dfrac{n*2^{256}} {(n*2^{256}/work)}
$$

$$
= \dfrac{n*2^{256}*work} {n*2^{256}}
$$

$$
= work
$$
