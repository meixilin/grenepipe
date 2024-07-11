# =================================================================================================
#     Trimming
# =================================================================================================


rule trim_reads_se:
    input:
        unpack(get_fastq),
    output:
        fastq=(
            "trimmed/{sample}-{unit}.fastq.gz"
            if config["settings"]["keep-intermediate"]["trimming"]
            else temp("trimmed/{sample}-{unit}.fastq.gz")
        ),
        qc="trimmed/{sample}-{unit}.qc-se.txt",
        done=touch("trimmed/{sample}-{unit}.se.done"),
    params:
        adapters=config["params"]["cutadapt"]["se"]["adapters"],
        extra=config["params"]["cutadapt"]["se"]["extra"],
    threads: config["params"]["cutadapt"]["threads"]
    log:
        "logs/cutadapt/{sample}-{unit}.log",
    benchmark:
        "benchmarks/cutadapt/{sample}-{unit}.bench.log"
    conda:
        # yet another missing dependency in the original wrapper...
        "../envs/cutadapt.yaml"
    wrapper:
        "0.74.0/bio/cutadapt/se"


rule trim_reads_pe:
    input:
        unpack(get_fastq),
    output:
        fastq1=(
            "trimmed/{sample}-{unit}.1.fastq.gz"
            if config["settings"]["keep-intermediate"]["trimming"]
            else temp("trimmed/{sample}-{unit}.1.fastq.gz")
        ),
        fastq2=(
            "trimmed/{sample}-{unit}.2.fastq.gz"
            if config["settings"]["keep-intermediate"]["trimming"]
            else temp("trimmed/{sample}-{unit}.2.fastq.gz")
        ),
        qc="trimmed/{sample}-{unit}.qc-pe.txt",
        done=touch("trimmed/{sample}-{unit}.pe.done"),
    params:
        adapters=config["params"]["cutadapt"]["pe"]["adapters"],
        extra=config["params"]["cutadapt"]["pe"]["extra"],
    threads: config["params"]["cutadapt"]["threads"]
    log:
        "logs/cutadapt/{sample}-{unit}.log",
    benchmark:
        "benchmarks/cutadapt/{sample}-{unit}.bench.log"
    conda:
        # yet another missing dependency in the original wrapper...
        "../envs/cutadapt.yaml"
    wrapper:
        "0.74.0/bio/cutadapt/pe"


# =================================================================================================
#     Trimming Results
# =================================================================================================


def get_trimmed_reads(wildcards):
    """Get trimmed reads of given sample-unit."""
    if is_single_end(wildcards.sample, wildcards.unit):
        # single end sample
        return [
            "trimmed/{sample}-{unit}.fastq.gz".format(sample=wildcards.sample, unit=wildcards.unit)
        ]
    elif config["settings"]["merge-paired-end-reads"]:
        # merged paired-end samples
        raise Exception(
            "Trimming tool 'cutadapt' cannot be used with the option 'merge-paired-end-reads'"
        )
    else:
        # paired-end sample
        return expand(
            "trimmed/{sample}-{unit}.{pair}.fastq.gz",
            pair=[1, 2],
            sample=wildcards.sample,
            unit=wildcards.unit,
        )


def get_trimming_report(sample, unit):
    """Get the report needed for MultiQC."""
    if is_single_end(sample, unit):
        # single end sample
        return "trimmed/" + sample + "-" + unit + ".qc-se.txt"
    elif config["settings"]["merge-paired-end-reads"]:
        # merged paired-end samples
        raise Exception(
            "Trimming tool 'cutadapt' cannot be used with the option 'merge-paired-end-reads'"
        )
    else:
        # paired-end sample
        return "trimmed/" + sample + "-" + unit + ".qc-pe.txt"
