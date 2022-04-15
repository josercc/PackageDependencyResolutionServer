struct DumpPackageResponse: Codable {
    let dependencies:[Dependencie]
}
extension DumpPackageResponse {
    struct Dependencie: Codable {
        let sourceControl:[SourceControl]
    }
}

extension DumpPackageResponse.Dependencie {
    struct SourceControl: Codable {
        let identity:String
        let location:Location
        let requirement:Requirement
    }
}

extension DumpPackageResponse.Dependencie.SourceControl {
    struct Location: Codable {
        let remote:[String]
    }
}

extension DumpPackageResponse.Dependencie.SourceControl {
    struct Requirement: Codable {
        let range:[Range]?
        let exact:[String]?
        let branch:[String]?
        let revision:[String]?
    }
}

extension DumpPackageResponse.Dependencie.SourceControl.Requirement {
    struct Range: Codable {
        let lowerBound:String
        let upperBound:String
    }
}